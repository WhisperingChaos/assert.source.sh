#!/bin/bash
# NOTES
#	> Variables declared within the functions below are prefixed by 'asrt'.
#	This prefix acts as a namespace to avoid accidentially colliding with
#	variables that are passed to the assert functions.
#	> Function & global variable names prefixed by "assert__"... are considered
#	private to this include	file - they should only be used/called by functions
#	within it.

# initialize default behavior
assert_source_init(){
	assert_bool_performant
	assert_continue
}
# use this public constant variable to prefix the lines in the expected test
# output to perform a regex comparison when comparing it to the generated output
# instead of simple equality.
assert_REGEX_COMPARE='<RegEx>'
assert_INPUT_CMD_DELIMITER='---'
# public assert_output_* functions expect a command as the first argument
# followed by zero or more of its arguments.  Note - first argument can be 
# compound - containing both a command and a single varable. ex: "echo hello"
# but this form won't work for functions of two or more parameters due to 
# bash's line spliting algorithm. 
assert_output_true(){
	assert__output_bool ' ' "$@"
}
assert_output_false(){ 
	assert__output_bool '!' "$@"
}
assert__output_bool(){
	# execute expected function before defining many other
	# local variables to ensure generation function binds,
	# if it needs to, to variables declared outside the
	# scope of this function. 
	local -i asrtPasInputPos
	local -i asrtPasOutLen
	assert__cmd_input_find 'asrtPasInputPos' 'asrtPasOutLen' "${@:2}"
	local asrtFDesc
	if [ "$2" == "$assert_INPUT_CMD_DELIMITER" ] || [ $# -eq 1 ]; then
		# expected output is empty
		exec {asrtFDesc}< <( : ) 
	else
		exec {asrtFDesc}< <( $2 "${@:3:$asrtPasOutLen}" 2>&1 )
	fi
	local -r asrtNegate="$1"
	local asrtIsCompareFail='true'
	local -i asrtGeneratedCnt
	local -i asrtExpectedCnt
	local asrtPasExpectedOuptput
	local asrtPasGeneratedOuptput
	while true; do
		# read from STDIN first
		local -i asrtPasGenInCnt
		local -i asrtPasExptOutCnt
		if [ "$asrtPasInputPos" -gt 0 ]; then
			local asrtCmmndGen="${@:$asrtPasInputPos+2:1}" 
			asrtCmmndGen="${asrtCmmndGen:-:}"
			# asrtCmmndGen="${asrtCmmmdGen:-:}"
			# read from provided input generation function
			if ! assert__output_compare "$asrtNegate" "$asrtFDesc"	\
				'asrtPasGenInCnt' 'asrtPasExptOutCnt'				\
				'asrtPasGeneratedOutput' 'asrtPasExpectedOutput'	\
				< <( $asrtCmmndGen "${@:$asrtPasInputPos+3}" 2>&1); then
				break
			fi
		elif ! assert__output_compare "$asrtNegate" "$asrtFDesc"	\
				'asrtPasGenInCnt' 'asrtPasExptOutCnt'				\
				'asrtPasGeneratedOutput' 'asrtPasExpectedOutput'; then
			break
		fi
		(( asrtGeneratedCnt = asrtPasGenInCnt ))
		(( asrtExpectedCnt  = asrtPasExptOutCnt ))
		while read -r -u $asrtFDesc; do
			((asrtExpectedCnt++))
		done
		asrtIsCompareFail='false'
		break
	done
	# always close expected output file handle
	eval exec $asrtFDesc\>\&\- 
	if $asrtIsCompareFail; then
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__msg_failed							\
			"generated='$asrtPasGeneratedOutput'"	\
	   		"expected_='$asrtPasExpectedOutput'"	
		assert__raised_record
		assert__halt_check
		return 1
	fi

	if [ $asrtGeneratedCnt -eq 0 ] && [ $asrtExpectedCnt -eq 0 ] && [ "$asrtNegate" == '!' ]; then
		# nothing generated but expect something due to 'assert_output_false'
		# provided nothing to expect :: expecting at least something.
		assert__msg_failed				\
			"generated='nothing'"		\
			"expected_='something'"
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
	if eval \[ \$asrtGeneratedCnt \-ne \$asrtExpectedCnt \]  \&\& $asrtNegate true ; then 
		# assert_output_true must inspect and apply the comparision operator
		# to the output list containing the most elements.  Therefore a mismatch 
		# signals ether expected or generated output that hasn't been compared.   
		# assert_output_false ensures that every element compared in the smallest
	    # defined set fails and considers absence of not expected elements
		# or not generated ones as a failure that affirms this assertion.
		assert__msg_failed						\
			"generatedCnt='$asrtGeneratedCnt'"	\
			"expected_Cnt='$asrtExpectedCnt'"
		# note when participating in a pipe, recording and halting
		# don't affect the parent process
		assert__raised_record
		assert__halt_check
		return 1
	fi
}
assert__cmd_input_find(){
	local -r asrtRtnInputPos="$1"
	local -r asrtRtnOutLen="$2"
	shift 2
	local -i asrtOutLen=$#
	local -i asrtInputPos=0
	local -i asrtDelmPos
	for (( asrtDelmPos=1; $# > 0; asrtDelmPos++ )){
		if [ "$1" == "$assert_INPUT_CMD_DELIMITER" ]; then
			(( asrtInputPos=asrtDelmPos ))
			break
		 fi
		shift
	}
	if [ $asrtInputPos -gt 0 ]; then
		(( asrtOutLen = asrtInputPos - 1 ))
	fi
	if [ $asrtOutLen -gt 0 ]; then
		(( asrtOutLen-- ))	
	fi
	eval $asrtRtnInputPos=\$asrtInputPos
	eval $asrtRtnOutLen=\$asrtOutLen
}
assert__output_compare(){
	local -r asrtNegate="$1"
	local -r asrtFDesc="$2"
	local -r asrtRtnGenInCnt="$3"
	local -r asrtRtnExptOutCnt="$4"
	local -r asrtRtnGeneratedOuptput="$5"
	local -r asrtRtnExpectedOuptput="$6"

	local asrtCompOper
	local asrtEval
	local asrtGenerated
	local asrtGeneratedCnt=0
	local asrtExpected
	local asrtExpectedCnt=0
	while read -r asrtGenerated; do
		((asrtGeneratedCnt++))
		if ! read -r -u $asrtFDesc asrtExpected; then
			# expected finished but now exhaust generated to update its counter.
			continue
		fi
		((asrtExpectedCnt++))
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
			eval $asrtRtnGeneratedOuptput=\"\$asrtGenerated\"
			eval $asrtRtnExpectedOuptput=\"\$asrtExpected\"
			return 1
		fi
	done
	eval $asrtRtnGenInCnt=\"\$asrtGeneratedCnt\"
	eval $asrtRtnExptOutCnt=\"\$asrtExpectedCnt\"
}
assert_true(){
	assert__bool "$1" ' ' "${@:2}"
}
assert_false(){
	assert__bool "$1" '!' "${@:2}"
}
assert__bool(){
	assert__msg_failed							\
		"Must select assert's implementation."	\
   		"Call either: assert_performant or assert_detailed."
	assert__raised_record
	assert__halt_check
}

assert__condition_code_set(){
	return $1
}

assert__msg_failed(){
	echo "msg='${FUNCNAME[2]} failed'" >&2
	echo " +  $1" >&2
	echo " +  $2" >&2
	echo " +  lineNo=${BASH_LINENO[2]}" >&2
	# indirectly called from failing test :: use [3] to identify it.
	echo " +  source='${BASH_SOURCE[3]}' func='${FUNCNAME[3]}'" >&2
}
###############################################################################
#
#	functions below adapt the public implementations defined above.
#
###############################################################################
assert_bool_performant(){
	assert__bool(){
	local -r asrtErrorCode="$?"
	local -r asrtExpression="$1"
	local -r asrtNegate="$2"

	# eliminate two static arguments to align this routine's $1-N with callers.
	# allows caller to encapsulate references to its $1-N, eliminating difficult
	# string concatenation/escaping when defining tests. 
	shift 2
	# set condition code so $? reference reflects the instruction immediately
	# prior to the current assert call.  Allows caller to encapsulate $?
	# reference with same benefts as described above.
	assert__condition_code_set $asrtErrorCode
	# performant as simple eval within existing shell - no forking required
	# nor output captured. Also, evaluation syntax failure will cause current
	# shell, the one running asserts, to abnormally terminate with the syntax error
	if eval $asrtNegate $asrtExpression; then
		return
	fi
	# Reveal $variables to better diagnose reason for assertion 
	# failure.  Requires running eval on the expression.  However, as best
    # as possible, limit this evaluation to only variable substitution,
	# to avoid possible secondary side effects, that could result in disaster. 
	# Essentially, your fully responsible for the outcome during the first
    # complete evaluation of the assert.  You're also fully responsible for 
	# the effects of the second evaluation below, however, the code attempts
	# to limit the scope of this second evaluation to variable substitution
	# to avoid harmful side effects.  "attempts" means that the code below
   	# isn't guaranteed to restrict evaluation to only variable
	# substitutions but it's fairly robust given its simplicity.
	#
	# Finally, simply exposing the $variable values is typically enough in most
	# cases to deterine the cause of an assert failure. 

	# escape delimiters that cause spawning of shells and redirection of output 
	local asrtExpEval="$( echo "$asrtExpression" | sed -e 's/\([()`"|><]\)/\\\1/g' )" 
	assert__condition_code_set $asrtErrorCode
	# quotes within echo to preserve spaces.  Won't work in all situations.
  	asrtExpEval="$( eval echo \"$asrtExpEval\" )"
	assert__msg_failed								\
		"expression=$asrtNegate $asrtExpression"	\
   		"evalExpres=$asrtNegate $asrtExpEval"
	assert__raised_record
	assert__halt_check
	}
}
assert_bool_detailed(){
	assert__bool(){
	local -ri asrtErrorCode=$?

	local asrtOutputCapture
	asrtOutputCapture="$(assert__bool_encap "$1" "$2" "$asrtErrorCode" "${@:3}" 2>&1)"
	if [ $? -eq 0 ]; then return; fi
	assert__msg_failed		\
		"expression=$2 $1"	\
   		"see set -x output below:"
	echo "$asrtOutputCapture"
	assert__raised_record
	assert__halt_check
	}
}
assert__bool_encap(){
	local -r asrtExpression="$1"
	local -r asrtNegate="$2"
	local -r asrtErrorCode="$3"
	# eliminate three static arguments to align this routine's $1-N with callers.
	# allows caller to encapsulate references to its $1-N, eliminating difficult
	# string concatenation/escaping when defining tests. 
	shift 3
	set -x
	# set condition code so $? reference reflects the instruction immediately
	# prior to the current assert call.  Allows caller to encapsulate $?
	# reference with same benefts as described above.
	assert__condition_code_set $asrtErrorCode
	eval $asrtNegate $asrtExpression; 
}
# default implementation supporting asserts that immediately halt or continue
assert__RAISED_SOMETIME_DURING_EXECUTION='false' 
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
	assert__RAISED_SOMETIME_DURING_EXECUTION='true'
}
assert__halt_check(){
	return 1
}
assert_return_code_set(){
	! $assert__RAISED_SOMETIME_DURING_EXECUTION
}
assert_return_code_child_failure_relay(){
	local asrtErrorCodeChild=$?

	while true; do
		if [ -z "$1" ]; then
			local -r asrtErrorCodeChild
			break
		fi
		$@
		local -r asrtErrorCodeChild=$?
		break
	done

	if [ $asrtErrorCodeChild -ne 0 ]; then
		assert__raised_record
		assert__halt_check
	fi
}

assert_source_init
