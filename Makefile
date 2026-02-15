setup:
	fvm use --fvm-skip-input --force
	melos bs
	melos run build --no-select

build:
	melos run build --no-select

get:
	melos run get --no-select

analyze:
	melos run analyze --no-select