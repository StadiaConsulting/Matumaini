.PHONY:	build clean plan

build:
	${INFO} "building"
	${INFO} "build complete"

clean:
	${INFO} "cleaning"
	${INFO} "clean compete"

plan:
	${INFO} "planning"
	${INFO} "plan complete"

# Cosmetics - Setting colors to be used in output
YELLOW := "\e[1;33m"
NC := "\e[0m"


# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "==> $$1"; \
	printf $(NC)' VALUE
