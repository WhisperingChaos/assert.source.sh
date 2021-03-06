[![Actions Status](https://github.com/whisperingchaos/assert.source.sh/workflows/test/badge.svg)](https://github.com/WhisperingChaos/assert.source.sh/actions)

# assert.source.sh
Provide yet another assertion package for testing.  Primarily for Bash scripting but can be broadly applied to CLI programs that affect environment variables or generate output.
### ToC 
[API Index](#api-index)  
[API](#api)  
[Install](#install)  
[Example](#example)  
[Test](#test)  
[Terms](#terms)  
[License MIT](LICENSE)  

### API Index
[assert_true \<bashTestEncapsulted\> ["${@}"]](#assert_true-bashtestencapsulted-)

[assert_false \<bashTestEncapsulted\> ["${@}"]](#assert_false-bashtestencapsulted-)

[assert_output_true [\<commandExpected\> [\<argList\>]] \<inputDelim\> \<commandGenerate\> [\<argList\>]](#assert_output_true-commandexpected-arglist-inputdelim-commandgenerate-arglist)

[assert_output_false [\<commandExpected\> [\<argList\>]] \<inputDelim\> \<commandGenerate\> [\<argList\>]](#assert_output_false-commandexpected-arglist-inputdelim-commandgenerate-arglist)

[assert_{true/false} '\<commandGenerate\> [\<argList\>] | assert_output_{true/false} [\<commandExpected\> [\<argList\>]]'](#assert_truefalse-commandgenerate-arglist--assert_output_truefalse-commandexpected-arglist)

[assert_bool_performant](#assert_bool_performant)

[assert_bool_detailed](#assert_bool_detailed)

[assert_halt](#assert_halt)

[assert_continue](#assert_continue)

[assert_return_code_set](#assert_return_code_set)

[assert_return_code_child_failure_relay [\<childCommand\> [\<argList\>]]](README.md#assert_return_code_child_failure_relay-childcommand-arglist)

### API

#### assert_true \<bashTestEncapsulted\> ["${@}"]
Generate message indicating failure of stated condition when **\<bashTestEncapsulated\>** evaluates to *false*.  Otherwise, be silent.

  * **\<bashTestEncapsulated\>** any Bash [conditional expression](https://www.gnu.org/software/bash/manual/html_node/Bash-Conditional-Expressions.html) [cocooned](#cocoon) to satisfy its parser so it treats the expression as a single argument.  This delays the expression's evaluation so it can occur within the implementation of **assert_true**.
```
    pasContext="unexpected context"
    assert_true '[ "$pasContext" == "expected context" ]' 
```
   *  **["${@}"]** forwards current argument values, $1-$N, of the function calling **assert_true**.  The position and values of these forwarded arguments are preserved within **assert_true** enabling the writting of **\<bashTestEncapsulated\>** expressions involving these arguments to reflect the presepective of the calling function.
  ```
    adminNm(){
        assert_true '[ "$1" == '\''admin'\'' ]' "${@}"
    }
    adminNm 'admin'
  ```
#### assert_false \<bashTestEncapsulted\> ["${@}"]
Negated form of [assert_true](#assert_true-bashtestencapsulted-).

#### assert_output_true [\<commandExpected\> [\<argList\>]] \<inputDelim\> \<commandGenerate\> [\<argList\>]
Compares the output, produced by **\<commandGenerate\>** to the output supplied by **\<commandExpected\>**.  The first comparison failue between these outputs produces an error message.  Otherwise, be silent (all outputs match).  Comparison failures include situations where one command produces more output than the other one.

This alternate form, differs from [piping](http://www.linfo.org/pipes.html) *(|)*, as it captures both STDOUT and STDERR of **\<commandGenerate\>** function and executes **assert_output_true** within the current process.  Also it's generally simpler to encode than piping and ensures proper assertion behavior.  A more indepth explaination follows.
  * **[\<commandExpected\>]** An optional addressible Bash function or CLI command whose STDOUT and STDERR will be consumed as input by **assert_output_true**.  If omitted or fails to generate output, **\<commandGenerate\>** must also omitt output from STDOUT and STDERR to affirm the assertion. In situations when **\<commandExpected>** produces output, each output line can be selectively prefixed by *${assert_REGEX_COMPARE}* *('\<RegEx\>')* to dynamically switch between an exact or regex pattern match.  See below for details.   
  * **[\<argList\>]** An optional list of arguments passed to  **\<commandExpected\>**.
  * **\<inputDelim\>** A pattern separating the invocation and associated parameters of **\<commandExpected\>** from **\<commandGenerate\>**.  It's defined by *${assert_INPUT_CMD_DELIMITER}* *('---')*.
  * **\<commandGenerate\>** An addressible bash function or CLI command whose STDOUT and STDERR will be consumed unaltered by **assert_output_true** and compared to **\<commandExpected\>**.
  * **[\<argList\>]** An optional argument list passed into **\<commandExpected\>**.
    
The comparision function uses the Bash *read* command to consume the output produced by both commands. Each *read* command transfers its data into an environment variable.  The content of the two environment variables are then compared to detect differences between the outputs produced by **\<commandGenerate\>** and **\<commandExpected\>**.  When first devised, a smallish collection of human readable newline terminated text was expected as the output supplied by **\<commandGenerate\>** and **\<commandExpected\>**.  However, *read* also consumes any data streamed via STDIN, including the contents of executable files.  Therefore, one can compare the contents of non-human readable sources as long as there's enough memory to maintain two, potentially complete, in memory replicas.  Furthermore, the comparison function offers both regular expresssion and simple equality matching.

Equality matching performs an exact binary comparision between a newline delimited block of bytes read from **\<commandGenerate\>** correlated to a corresponding newline delimited block of bytes read from **\<commandExpected\>**.  Although this uncompromising form of comparision offers a generally useful operator, it can be dynamically replaced by a regular expression comparator providing flexible pattern matching.  To dynamically specify a regular expression comparator, prefix select newline delimited byte blocks with *${assert_REGEX_COMPARE}* during their construction by **\<commandExpected\>**.  As the comparator function process each delimited byte block, it tests for the presense of the regex prefix.  Its detection triggers the comparision function to apply Bash's regular expression operator *(=~)*, instead of Bash's exact string match one *(==)*.
```
commandGenerated(){
cat <<GEN
line_1
line_2
line_3 $(date +%m/%d/%y)
line_4
GEN
}
commandExpected(){
# first, second & forth line use ==
# third line applies regex comparison
cat <<EXPECTED
line_1
line_2
${assert_REGEX_COMPARE}line_3 .*
line_4
EXPECTED
}
assert_output_true commandExpected --- commandGenerated
```

The usual coding idiom to capture the output of **\<commandGenerate\>**  involves [piping](http://www.linfo.org/pipes.html) ex: ```test_5_generate | assert_output_true test_5_expected``` to feed STDIN of **assert_output_true** with the STDOUT of  **\<commandGenerate\>**.  Although this piped form will produce an appropriate message and return code *($?)*, other assert features, such as **assert_halt** and **assert_return_code_set**, rely on a source level variable to remember the outcome of an assert's execution.  Since piping starts an independent child process, updates to the source level variable performed by the child process are limited to the child process' copy of the parent process' source level variable.  Therefore, when the child process terminates, the parent process source level variable reflects the value last assigned to this variable immediately before starting the child process (by piping) discarding any changes applied by the child process while it ran.  There are at least two methods to circumvent this signal loss.

The easiest method to preserve changes to the source level variable employs the form of **assert_output_true** requiring the parameters **\<inputDelim\> \<commandGenerate\> [\<argList\>]**.  This form executes **assert_output_true** within the current process spawning a subprocess to execute **\<commandGenerate\> [\<argList\>]** capturing its STDOUT and STDERR for comparison.  By executing **assert_output_true** within the same process, changes to the source level variable are properly preserved ensuring the expected behavior of other assert features dependent on its value. 
```
test_5_generated(){
    echo "line-$1"
    echo "line_$2"
}
test_5_expected(){
    test_5_generated "${@}"
}
assert_output_true test_5_expected '1' '2' --- test_5_generated '1' '2'
```

The second method combines **assert_true** with **assert_output_true** by specifying **assert_output_true** as a **\<bashTestEncapsulted\>** expression.  In this situation, **assert_true** executes within the current process, allowing it to affect source variable vaues while **assert_output_true** is spawned as the last child process in a pipe.  This ordering of **assert_output_true** feeds the STDOUT of an upstream command to its STDIN.  Since **assert_output_true** will generate both an appropriate output and return code value, **assert_true** can then apply ("forward") the source level variable update that would have happened had **assert_output_true** been performed within the context of the parent process.
```
test_5_generated(){
    echo "line-$1"
    echo "line_$2"
}
test_5_expected(){
    test_5_generated "${@}"
}
assert_true "test_5_generated '1' '2' | assert_output_true test_5_expected '1' '2'"
```
One desirable behavior of this form is its innate ability to restrict sampling **\<commandGenerate\>** output to STDOUT. Streaming only  STDOUT to **assert_output_true** differienciates this form from the other one that always consumes STDOUT and STDERR. However, there are some downsides to the piping approach: 
  * The difficulty in properly [cocooning](#cocoon) a potentially complex expression.
  * The additional assertion failure message produced by **assert_true** which appears immediately after the one generated by **assert_output_true**.

#### assert_output_false [\<commandExpected\> [\<argList\>]] \<inputDelim\> \<commandGenerate\> [\<argList\>]
Negated form of **assert_output_true**.  Requires every delimited block of bytes generated by **\<commandGenerate\>** be different from its corresponding block produced by **\<commandExpected\>**. Otherwise, if at least one corresponding block matches, this assertion is triggered.  In constrast to **assert_output_true**, a mismatch in the number of either **\<commandGenerate\>** or **\<commandExpected\>** will affirm the assertion, as long as the provided compared outputs preserve it.  

#### assert_{true/false} '\<commandGenerate\> [\<argList\>] | assert_output_{true/false} [\<commandExpected\> [\<argList\>]]'
A piped version of **assert_output_{true/false}**.  This form is expained within the context of [**assert_output_true**](#assert_output_true-commandexpected-arglist-inputdelim-commandgenerate-arglist).  

#### assert_bool_performant
Implements the evaluation of **assert_true** within the current process - doesn't spawn a child process. Therefore, an incorrectly formed **\<bashTestEncapsulted\>** will terminate the current process.  Also, an evaluation violating the constraint enforced by an assert is performed a second time in order to generate a useful message.  The code attempts to limit this second evaluation to only environment variables, as evaluating other expressions, like those used to start a subprocess, may result in undesirable side effects when executed a second time.  In general, limiting evaluation to only environment variables is usually sufficient to debug the assert failure.  However, in certain situations, a more detailed evaluation of the expression can be produced using **assert_bool_detailed**

The assert package uses this performant form as its default implementation.
```
# by default, don't have to call assert_bool_performant
assert_false '[ "$1" == "b"]'
assert_true '[ "$1" == "a" ]'
.
.
```
#### assert_bool_detailed
Implements the evaluation of **assert_{true|false}** within a subprocess of the current one.  It uses *set -x* and captures its output providing a detailed trace of the entire **\<bashTestEncapsulted\>** expression.  Capturing is performed as the expression is evaluated, therefore, a second evaluation, to generate a message when the assert fails isn't required, as is the case when using **assert_bool_performant**.  Due to subprocess spawning, **assert_bool_detailed** is resilient to problematic expressions that would cause the performant implementation to abnormally terminate its current process.  However, it does fork a subshell which "costs" some amount of time and resources.  Furthermore, subprocess spawing initiated by **assert_bool_detailed** prevents it from replacing **assert_bool_performant** in situations where the tested code relies on intentional side effects.

For example, a Bash function can accept a variable name as argument.  Then within the function, the passed variable can be assigned a different value.  This value is now available to the calling function via the shared variable name.  Moreover, it isn't necessary to pass a variable name as an argument.  The called code can simply update any writeable environment variable declared within the context of the calling function. However, in either situation, an intentional write operation can be thwarted when the called function executes within a child process spawned by the calling function.  A calling function that spawns (forks) a child process protects its memory from a called function's (child process') write operations due to fork's [COW mechanism](https://en.wikipedia.org/wiki/Copy-on-write).  Since **assert_bool_detailed** alters the implementaton of **assert_{true|false}** to fork a child process, an **assert_{true|false}** executing code, like a Bash function, written to rely on an intentional side affect, will fail because the called code cannot communicate the intentional side affect across the process boundry established by **assert_bool_detailed**.
```
	.	
	.
	local sharedVar=5
	assert_bool_detailed
	assert_true called 'sharedVar'
	# this assert will fail due to the fork performed within assert_true's
	# implement defined by assert_bool_detailed.  sharedVar's value remains 5.
	assert_true '[ $sharedVar == 6 ]'
	assert_bool_performant
	assert_true called 'sharedVar'
	# this assert will succeed as assert_true's implementation, defined by
	# assert_bool_performant, executes 'called' within the same process as this
	# calling function.
	assert_true '[ $sharedVar == 6 ]'
	.
	.
called(){
	eval $1\=\6
}

```

In situations involving assertions reliant on side effects, like the one demonstrated by example above, either always call **assert_bool_performant** before executing the asserted code or execute the code independent of an **assert_{true|false}** then apply the assert to test the side affect.

Typically, its more resource efficient and speedier to use the implementation of **assert_bool_performant**.  However, since either implementation can dynamically replace the other, except in the situation mentioned above, it might be advisable to use **assert_bool_detailed** when first developing a test script, due to its reliability and detailed evaluation output, then once the test script becomes stable, simply replace it with **assert_bool_performant**.
```
# using detailed implementation of assert_true
assert_bool_detailed
assert_true '[ "$1" == "$( echo "b") ]'
.
.
# replace detailed implenentation of assert_true with performant version
assert_bool_performant
assert_false '[ "$1" == "b"]'
assert_true '[ "$1" == "a" ]'
.
.
```

#### assert_halt
After invoking this function, the next failure detected by an assertion will cause the current process to abruptly terminate with an error code of '1'.

#### assert_continue
After invoking this function, the current process will continue execution through failures detected by subsequent assertions.  When assertion failures occur in this mode, the fact that a failure occurred is remembered.  This is the default behavior of this assertion package.  Once testing completes, the **assert_return_code_set** can be called to establish the return code value for the entire test.  

#### assert_return_code_set
A function whose execution sets the return code for the process.  Encode it as the last command executed by the test script, especially when testing through assertions by specifying **assert_continue** mode (the package's default behavior).

#### assert_return_code_child_failure_relay [\<childCommand\> [\<argList\>]]
Relays a failure ```[ $? -ne 0 ]```, communicated by a child command's return code, to its parent command.  Although other assert functions above can fullfill a similar role, it might be undesirable to issue another assert message (noise) if the child process already generates an appropriate assert message.  Furthermore, if desired, the childCommand can execute immediately above this function instead of specifying the childCommand as a set of arguments to it.

```
...

	assert_return_code_child_failure_relay 'test_assert_child_process_run'

...

test_assert_child_process_run()(
	# initiate function as child process.  Notice use of "()" instead of "{}" used to define function body.
	# Bash (Linux) starts child process with nearly exact state of parent.  Linux uses Copy On Write
	# (https://en.wikipedia.org/wiki/Copy-on-write) mechanism to shield parent process from memory updates
	# performed by the child.  Therefore, assert_ invocations in this child process fail to affect the state
	# of the assert_ package active in the parent.

	# raise an assertion.
	assert_true false
	# communicate failure to parent process by setting the return code according to the assert package instance
	# running within this child.
	assert_return_code_set	
)
```


### Install
Simply copy **assert.source.sh** into a directory then use the Bash [source](https://www.gnu.org/software/bash/manual/html_node/Bash-Builtins.html#Bash-Builtins) command to include this package in a Bash testing script before executing fuctions which rely on its [API](#api-index).  Copying using:

  * [```git clone```](https://help.github.com/articles/cloning-a-repository/) to copy entire project contents including its git repository.  Obtains current master which may include untested features.  To synchronize the working directory to reflect the desired release, use ```git checkout tags/<tag_name>```.
  *  [```wget https://github.com/whisperingchaos/assert.source.sh/tarball/master```](https://github.com/whisperingchaos/assert.source.sh/tarball/master) creates a tarball that includes only the project files without the git repository.  Obtains current master branch which may include untested features.
    
#### Developed Using 
  * GNU Bash  4.2.25(1)-release
  
### Example
[example.source_test.sh](test/example.source_test.sh)

### Test
After [installing](#install), change directory to **assert.source.sh**'s ```test``` directory and run [**assert.source_test.sh**](test/assert.source_test.sh).  It should complete successfully and not produce any messages.
```
host:~/Desktop/projects/assert.source.sh/test$ ./assert.source_test.sh
host:~/Desktop/projects/assert.source.sh/test$ 
```
  
### Terms
#### Cocoon
An expression encaspulation mechanism that prevents immediate evaluation.
Mechanisms include:
  * Bash single quoting.  When single quotes must themselves be encapsulated, Bash offers string concatenation.  
  ```
  $ echo 'encapsulated string: ">|#()<?[{}]:!'
  encapsulated string: ">|#()<?[{}]:!
  ```
  * Bash string concatenation.
  ```
  $ echo 'encapsulated string including single quote: ">|#()<?'"'"'[{}]:!'
  encapsulated string including single quote: ">|#()<?'[{}]:!
  ```
  * Bash single character concatenation.
  ```
  $ echo 'encapsulated string: ">|#()<?'\'\e\f\g'[{}]:!'
  encapsulated string: ">|#()<?'efg[{}]:!
  ```
  * Indirect expression evaluation via Bash function call.
```
#!/bin/bash
source ../component/assert.source.sh
express_encap(){
    [ "$1" == 'Beautiful' ] && ([ "$2" == "Morning" ] || [ "$2" == 'Evening' ]) 
}
sunrise(){
    assert_true 'express_encap "${@}"' "${@}"
}
sunrise 'Beautiful' 'Morning'
```
  
### References

[lehmannro/assert.sh](https://github.com/lehmannro/assert.sh)
