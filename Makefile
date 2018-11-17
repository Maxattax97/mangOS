SCRIPTS=./scripts/

all: detect-root build-nonlibre build-libre

detect-root:
	@bash "${SCRIPTS}/detect-root.sh"

build-libre: detect-root
	@bash "${SCRIPTS}/build.sh" libre

build-nonlibre: detect-root
	@bash "${SCRIPTS}/build.sh" nonlibre

