all: up

up:
	vagrant up --provision

reload:
	vagrant reload

provision:
	vagrant provision

fclean:
	vagrant destroy -f

re: fclean all

.PHONY: up re fclean all reload
