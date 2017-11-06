#!/bin/bash
assert_output_true(){
	assert__output_bool "$1" '!'
}
assert_output_false(){ 
	assert__output_bool "$1" ' '
}
assert__output_bool(){
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
	assert__bool "$1" '!'
}

assert_false(){
	assert__bool "$1" ' '
}

assert__bool(){
	local -r expression="$1"
	local -r negate="$2"

	if eval $negate $expression; then
		# indirectly called from failing test :: use [2] to identify it.  
		echo "status='${FUNCNAME[1]} failed' func='${FUNCNAME[2]}' lineno=${BASH_LINENO[2]} source='${BASH_SOURCE[2]}'" >&2
		return 1
	fi
	return 0
}
