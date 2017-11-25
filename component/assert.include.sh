#!/bin/bash
# NOTES
#	> Variables declared within the functions below are prefixed by 'asrt'.
#	This prefix acts as a namespace to avoid accidentially colliding with
#	variables that are passed to the assert functions.
#	> Function names with "assert__"... are considered private to this include
#	file - they should only be called by functions within it.

assert_REGEX_COMPARE='<RegEx>'
# assert_output functions accept only a single argument.  That argument, in most
# cases should be the name of a bash function that writes to sysout.  
assert_output_true(){
	assert__output_bool "$1" ' '
}
assert_output_false(){ 
	assert__output_bool "$1" '!'
}
assert__output_bool(){
	local -r asrtExpectedFn="$1"
	# execute expected function before defining many other
	# local variables to ensure generation function binds,
    # if it needs to, to variables declared outside the
	# scope of this function. 
	local asrtFDesc
	exec {asrtFDesc}< <( $asrtExpectedFn ) 
	local -r asrtNegate="$2"

	local asrtCompOper
	local asrtEval
	local asrtGenerated
	local asrtGeneratedCnt=0
	local asrtExpected
	local asrtExpectedCnt=0
	while read -r asrtGenerated; do
		((asrtGeneratedCnt++))
		if read -r -u $asrtFDesc asrtExpected; then
			((asrtExpectedCnt++))
		fi
		asrtCompOper='true'
		if [[ "${asrtExpected:0:${#assert_REGEX_COMPARE}}" == "$assert_REGEX_COMPARE" ]]; then
			asrtCompOper='false'
			asrtExpected="${asrtExpected:${#assert_REGEX_COMPARE}}"
		fi
		asrtEval='true'
		# need two different comparators statements: 
		#	1. Regex expressions, that appear in RHS of regex comparison,
	   	#	must not be encapsulated in quotes because if they are quoted,
		#	they are evaluated as just an ordnary string of characters.    
	    #	2. The equality operator requires both its operands encapsulated
	   	#	by double quotes to prevent certain characters like '[' and ']'
		#	from interferring with its evaluation.
		#	3. Finally, the LHS operand of a regex operator must also be
		#	quote encapulated for the very same reason the equality operator's
	   	#	LHS is encapsulted by quotes.
		if $asrtCompOper; then 
			eval $asrtNegate \[ \"\$asrtGenerated\" == \"\$asrtExpected\" \] \|\| asrtEval\=\'false\'
		else
			eval $asrtNegate \[\[ \"\$asrtGenerated\" =~ \$asrtExpected \]\] \|\| asrtEval\=\'false\'
		 fi
		 if ! $asrtEval; then
			eval exec $asrtFDesc\<\&\-
			echo "msg='${FUNCNAME[1]} failed'" >&2
			echo "  generated='$asrtGenerated'">&2
			echo "  expected_='$asrtExpected'" >&2	
			echo "  lineNo=${BASH_LINENO[1]}"  >&2
			# indirectly called from failing test :: use [2] to identify it.
			echo "  source='${BASH_SOURCE[2]}' func='${FUNCNAME[2]}'" >&2
			# note when participating in a pipe, recording and halting
			# don't affect the parent process
			assert__raised_record
			assert__halt_check
			return 1
		fi
	done
	while read -r -u $asrtFDesc; do
		((asrtExpectedCnt++))
	done
	eval exec $asrtFDesc\>\&\- 
	if [ $asrtGeneratedCnt -ne $asrtExpectedCnt ]; then 
		echo "msg='${FUNCNAME[1]} failed'" >&2
		echo "  generatedCnt='$asrtGeneratedCnt'">&2
		echo "  expected_Cnt='$asrtExpectedCnt'" >&2	
		echo "  lineNo=${BASH_LINENO[1]}"  >&2
		# indirectly called from failing test :: use [2] to identify it.
		echo "  source='${BASH_SOURCE[2]}' func='${FUNCNAME[2]}'" >&2
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
	true
}
assert_true(){
	assert__bool "$1" ' '
}
assert_false(){
	assert__bool "$1" '!'
}
assert__bool(){
	local -r asrtExpression="$1"
	local -r asrtNegate="$2"

	if eval $asrtNegate $asrtExpression; then
		return
	fi
	echo "msg='${FUNCNAME[1]} failed'" >&2
	echo "  expression=$asrtNegate $asrtExpression" >&2
	eval echo \' \ evalExpres=\'\"\$asrtNegate\ \"\"$asrtExpression\" >&2
	echo "  lineNo=${BASH_LINENO[1]}" >&2
	# indirectly called from failing test :: use [2] to identify it.
	echo "  source='${BASH_SOURCE[2]}' func='${FUNCNAME[2]}'" >&2
	assert__raised_record
	assert__halt_check
}
# default implementation supporting asserts that immediately halt or continue
assert_RAISED_SOMETIME_DURING_EXECUTION='false' 
assert_halt(){
	assert__halt_check(){
		exit 1
	}
}
assert_continue(){
	assert__halt_check(){
		return 1
	}
}
assert__raised_record(){
	assert_RAISED_SOMETIME_DURING_EXECUTION='true'
}
assert__halt_check(){
	return 1
}
assert_raised_check(){
	! $assert_RAISED_SOMETIME_DURING_EXECUTION
}

