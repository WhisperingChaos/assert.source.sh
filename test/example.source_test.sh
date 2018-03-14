#!/bin/bash
source base/assert.source.sh
source example.source.sh

test_assert(){
	local hostName="hNmGood1"
	# affirm environment variable value
	assert_true '[ "$hostName" == '\''hNmGood1'\'' ]'
	# affirm return code for function hostNameVerify is true when compliant hostname supplied
	assert_true 'hostNameVerify "$hostName"'
	# affirm no output is expected when compliant hostname supplied.
	assert_true 'hostNameVerify "$hostName" 2>&1 | assert_output_true'
	# alternate form of assert_output_true where it executes in process
	# relying on same side effect to realize the same outcome as prior assert.
	assert_output_true --- hostNameVerify "$hostName" 
	# assert hostNameVerify returned false and generated the appropriate error.
	assert_output_true echo "Error: hostName='bad' length=3 less than minAllowed=4" \
		--- assert_true 'hostNameVerify "bad"'
}

main(){
	test_assert
	assert_return_code_set	
}
main
