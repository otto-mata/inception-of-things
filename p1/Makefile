all: up

up: secret
	vagrant up

secret:
	openssl rand -hex -out $@ 64

fclean:
	vagrant destroy -f
	rm -f secret

re: fclean all

.PHONY: up re fclean all
