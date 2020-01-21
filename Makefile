.PHONY:	build clean plan

build:
	${INFO} "building"
	terraform apply
	${INFO} "build complete"

clean:
	${INFO} "cleaning"
	terraform destroy
	${INFO} "clean compete"

plan:
	${INFO} "planning"
	terraform plan
	${INFO} "plan complete"

# Cosmetics - Setting colors to be used in output
# list of colors - https://misc.flogisoft.com/bash/tip_colors_and_formatting
YELLOW := "\e[1;33m"
NC := "\e[0m"


# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "==> $$1"; \
	printf $(NC)' VALUE
