SCRIPTS=./scripts/
DOCKER=./docker/

all: nonlibre libre

libre:
	@bash "${SCRIPTS}/build.sh" libre

nonlibre:
	@bash "${SCRIPTS}/build.sh" nonlibre

docker:
	@bash "${DOCKER}/build.sh"

enter:
	@sudo bash "${DOCKER}/enter.sh"
