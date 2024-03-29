all:
	elm make src/Main.elm --output=elm.js

release:
	elm make --output=elm.js --optimize src/Main.elm
	uglifyjs elm.js --compress "pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe" | uglifyjs --mangle --output elm.js
	grep serviceVersion service.js

skip-worktree:
	git update-index --skip-worktree elm.js

no-skip-worktree:
	git update-index --no-skip-worktree elm.js
