#!/bin/bash
assert_output_true(){
	assert_output_bool "$1" '!'
}
assert_output_false(){ 
	assert_output_bool "$1" ' '
}
assert_output_bool(){
	local -r expectedFn="$1"
	local -r negate="$2"

	local input
	local inputCnt=0
	local expected
	local expectedCnt=0
	local fDesc
	exec {fDesc}< <( $expectedFn ) 
	while read -r input; do
		((inputCnt++))
		if read -r -u $fDesc expected; then
			((expectedCnt++))
		fi
		if eval $negate \[\[ \$input \=\~ \$expected \]\]; then 
			eval exec $fDesc\<\&\- 
			return 1
		fi
	done
	while read -r -u $fDesc; do
		((expectedCnt++))
	done
	eval exec $fDesc\>\&\- 
	if [ $inputCnt -ne $expectedCnt ]; then 
		return 1
	fi
	true
}
assert_true(){
	assert_bool "$1" '!'
}

assert_false(){
	assert_bool "$1" ' '
}

assert_bool(){
	local -r expression="$1"
	local -r negate="$2"

	if eval $negate $expression; then
		echo "status='${FUNCNAME[1]} failed' source=${BASH_SOURCE[2]} test='${FUNCNAME[2]}' lineno='${BASH_LINENO[1]}'" >&2
		return 1
	fi
	return 0
}
