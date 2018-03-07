# assert.source.sh
Provide yet another assertion library for testing.  Primarily for Bash scripting but can be broadly applied to CLI programs that affect environment variables or generate output.

### Public API

#### assert_true \<bashTestEncapsulted\> ["${@}"]
Generate message indicating failure of stated condition when **\<bashTestEncapsulated\>** evaluates to *false*.  Otherwise, be silent.

  * **\<bashTestEncapsulated\>** any bash [conditional expression](https://www.gnu.org/software/bash/manual/html_node/Bash-Conditional-Expressions.html) [cocooned](https://github.com/WhisperingChaos/assert.source.sh/blob/master/README.md#cocoon) to satisfy its parser so it treats the expression as a single argument.  This delays the expression's evaluation so it can occur within the implementation of **assert_true**.
```
    pasContext="unexpected context"
    assert_true '[ "$pasContext" == "expected context" ]' 
```
   *  **["${@}"]** forwards current argument values, $1-$N, of the function calling **assert_true**.  The position and values of these forwarded arguments are preserved within **assert_true** enabling the writting of **\<bashTestEncapsulated\>** expressions involving these arguments to reflect the presepective of the calling function.
  ```
    AdminNm(){
        assert_true '[ "$1" == 'admin' ]' "${@}"
    }
   
    AdminNm 'admin'
  ```
#### assert_false \<bashTestEncapsulted\> ["${@}"]
Negated form of *assert_true*.

#### assert_output_true \<commandExpected\> [\<argList\>] [\<inputDelim\> \<commandGenerate\> [\<argList\>]]
Compares the output, produced by \<commandGenerate\> to the output produced by \<commandExpected\>.  The first comparison failue between these outputs produces an error message.  Otherwise, be silent (all outputs match).  Comparison failures include situations where one command produces more output than the other one.

The comparision function uses the Bash *read* command to consume the output produced by both commands. Each *read* command transfers its data into an environment variable.  The content of the two environment variables are then compared to identify differences between the outputs produced by \<commandGenerate\> and \<commandExpected\>.  When devised, human readable text was expected as the output supplied by \<commandGenerate\> and \<commandExpected\>. Essentially, a smallish number of typically newline terminated text. However, *read* also consumes any data streamed via STDIN, including the contents of executable files.  Therefore, one can compare the contents of non-human readable sources as long as there's enough memory to maintain two, potentially complete, in memory replicas.  Furthermore, the comparison function offers both regular expresssion and simple equality matching.

Equality matching performs an exact binary comparision between a newline delimited block of bytes read from \<commandExpected\> correlated to a corresponding newline delimited block of bytes read from \<commandExpected\>.  Although this uncompromising form of comparision offers a generally useful operator, it can be dynamically replaced by a regular expression comparator providing flexible pattern matching.  To dynamically specify a regular expression comparator, the \<commandExpected\> would apply a prefix to select newline delimited byte block(s) and then encode the desired regex expression within this delimited byte block. As the comparator function process each delimited byte block, it tests for the presense of the regex prefix.  The existance of the regex prefix triggers the comparision function to apply Bash's regular expression operator *(=~)* instead of Bash's exact string match one *(==)*.  Dynamically switching between comparison operators 

The usual coding idiom to capture the output of \<commandExpected\>  involves [piping](http://www.linfo.org/pipes.html) ex: ```test_5_generate | assert_output_true test_5_expected``` to feed STDIN of **assert_output_true** with the STDOUT of  \<commandExpected\>.  Although this piped form will produce an appropriate message and return code *($?)*, other assert features, such as *assert_halt* and *assert_return_code_set*, rely on a source level variable to remember the outcome of an assert command.  Since piping starts and independent child process, updates to the source level variable performed by the child process are limited to the child process' copy of the parent process' source level variable.  Therefore, when the child process terminates, the parent process source level variable reflects the value last assigned to this variable immediately before starting the child process (by piping) discarding any changes applied by the child process while it ran.  There are at least two methods to circumvent this signal loss.

The easiest method to preserve changes to the source level variable employs the second form of **assert_output_true** requiring one to specify the parameters **\<inputDelim\> \<commandGenerate\> [\<argList\>]**.  This form executes **assert_output_true** within the current process spawning a subprocess to execute **\<commandGenerate\> [\<argList\>]** capturing its STDOUT for comparison.  By executing **assert_output_true** within the same process, changes to the source level variable are properly preserved ensuring the expected behavior of other assert features dependent on its value. 
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
Besides the method demonstrated above, a second one, more akin to the traditional piping mechanism, can be encoded.

The second method relies combining **assert_true** with **assert_output_true** specifying **assert_output_true** as a **\<bashTestEncapsulted\>** expression.  In this situation, **assert_true** executes within the current process, allowing it to affect source variable vaues while **assert_output_true** is spawned as the last child process in a pipe.  In this configuration **assert_output_true** is feed the STDOUT of an upstream command.  Since **assert_output_true** will generate both an appropriate output and return code value, **assert_true** can then apply ("forward") the source level variable update that would have happened had **assert_output_true** been performed within the context of the parent process.

The downsides of this approach include: 
  * The difficulty in properly [cocooning](https://github.com/WhisperingChaos/assert.source.sh/blob/master/README.md#cocoon) potentially complex expressions.
  * The additional assertion failure messages produced by **assert_true** which appear immediately after the ones generated by **assert_output_true**.



Although a bit more complex to specify, due to required concooning 

#### assert_output_false \<command\> [\<argList\>]
Negated form of *assert_output_true*.

#### assert_halt

#### assert_continue

#### assert_return_code_set

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
