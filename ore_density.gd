extends RefCounted

# Sparse supplies encourage exploring connected districts. Five Earth surfaces
# still provide ten starter-tool copper deposits, enough for the five-copper drill.
const SURFACE_COMMON := 2
const MINE_COMMON := 1
const MINE_RARE := 1

static func count(cave: bool) -> int:
	return MINE_COMMON + MINE_RARE if cave else SURFACE_COMMON
