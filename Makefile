# Add INSPECT to check return value.  Need to figure out what makes sense for terraform
INSPECT := $$(docker-compose -p $$1 -f $$2 ps -q $$3 | xargs -I ARGS docker inspect -f "{{ .State.ExitCode }}" ARGS)

# Add CHECK in conjunction with INSPECT
CHECK := @base -c '\
	if [[ $(INSPECT) -ne 0 ]]; \
	then exit $(INSPECT); fi' VALUE

.PHONY:	build-core clean plan-core

build-core:
	${INFO} "building core infrastructure"
	@ time terraform apply
	${INFO} "build complete - core infrastructure"

clean:
	${INFO} "cleaning core infrastructure"
	@ clean-static-web.sh
	@ time terraform destroy
	${INFO} "clean compete - core infrastructure"

plan core:
	${INFO} "planning core infrastructure"
	@ time terraform plan
	${INFO} "plan complete - core infrastructure"

# Cosmetics - Setting colors to be used in output
# list of colors - https://misc.flogisoft.com/bash/tip_colors_and_formatting
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "==> $$1"; \
	printf $(NC)' VALUE
