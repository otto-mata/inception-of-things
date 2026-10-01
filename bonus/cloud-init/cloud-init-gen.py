import argparse
import subprocess
import sys
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from uuid import uuid4

import jinja2 as j2
import jsonschema
import requests
import yaml
from jsonschema.exceptions import ValidationError
from yaml.parser import ParserError

SCHEMA_URL = "https://raw.githubusercontent.com/canonical/cloud-init/refs/heads/26.2/cloudinit/config/schemas/schema-cloud-config-v1.json"
WD = Path(__file__).resolve().parent


@dataclass
class File:
    path: str
    content: str
    owner: str
    permissions: str


@dataclass
class InstanceMetadata:
    id: str
    hostname: str


@dataclass
class UserDataTemplateData:
    files: list[File]
    runcmds: list[str]
    ssh_key: str


@dataclass
class MetaDataTemplateData:
    instance: InstanceMetadata


@dataclass
class TemplateRenderings:
    user_data: str
    meta_data: str


def validate(user_data: str):
    res = requests.get(SCHEMA_URL)
    obj = yaml.safe_load(StringIO(user_data))
    jsonschema.validate(obj, res.json())


def generate_from_templates(
    meta_data_template_name: str,
    user_data_template_name: str,
):
    scripts_dir = WD / "installers"
    env = j2.Environment(
        undefined=j2.StrictUndefined,
        loader=j2.FileSystemLoader(f"{WD / 'templates'}"),
    )
    meta_data = env.get_template(meta_data_template_name).render(
        data=MetaDataTemplateData(
            instance=InstanceMetadata(id=str(uuid4()), hostname="qemu-fedora-cloud"),
        )
    )

    ssh_identity_file = Path.home() / ".ssh" / "id_ed25519.pub"
    installers_path = Path("/opt/iot/installers")
    files = [
        File(
            path=str(installers_path / f.stem),
            content=yaml.safe_dump(
                f.read_text(),
                default_style="|",
                indent=6,
            ),
            owner="root:root",
            permissions="0500",
        )
        for f in scripts_dir.glob("*.sh")
    ]
    sysctl_service_name = "podman-docker.service"
    sysctl_service_dir = Path("/etc/systemd/system/")
    commands = [f.path for f in files]

    files.append(
        File(
            path=f"{sysctl_service_dir / sysctl_service_name}",
            content=yaml.safe_dump(
                (WD / "systemctl" / "podman-docker.service").read_text(),
                default_style="|",
                indent=6,
            ),
            owner="root:root",
            permissions="0644",
        )
    )
    user_data = env.get_template(user_data_template_name).render(
        data=UserDataTemplateData(
            files=files,
            runcmds=commands,
            ssh_key=ssh_identity_file.read_text(),
        ),
    )
    return TemplateRenderings(
        user_data=user_data,
        meta_data=meta_data,
    )


def generate_iso(
    meta_data_yaml: Path,
    user_data_yaml: Path,
):
    geniso = subprocess.run(
        args=[
            "genisoimage",
            "-output",
            "cloud-init.iso",
            "-volid",
            "cidata",
            "-joliet",
            "-rock",
            "-input-charset",
            "utf-8",
            str(meta_data_yaml.absolute()),
            str(user_data_yaml.absolute()),
        ],
        check=True,
        capture_output=True,
    )
    if geniso.returncode:
        print(geniso.stderr)
        sys.exit(geniso.returncode)


def main(no_iso: bool = False):

    user_data_yaml = WD / "user-data.yaml"
    meta_data_yaml = WD / "meta-data.yaml"

    renderings = generate_from_templates(
        "meta-data.yaml.j2",
        "user-data.yaml.j2",
    )
    try:
        validate(renderings.user_data)
    except (ParserError, ValidationError) as exc:
        print(f"[{exc.__class__.__name__}]:")
        print(exc)
        sys.exit(1)
    meta_data_yaml.write_text(renderings.meta_data)
    user_data_yaml.write_text(renderings.user_data)
    if not no_iso:
        generate_iso(
            meta_data_yaml,
            user_data_yaml,
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--no-iso", help="do not generate `cloud-init.iso`", action="store_true"
    )
    args = parser.parse_args()
    main(args.no_iso)
