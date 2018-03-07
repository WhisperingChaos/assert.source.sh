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

The comparision function uses the Bash *read* command to consume the output produced by both commands. Each *read* command transfers its data into an environment variable.  The content of the two environment variables are then compared to identify differences between the outputs produced by \<commandGenerate\> and \<commandExpected\>.  When devised, human readable text was expected as the output supplied by \<commandGenerate\> and \<commandExpected\>. Essentially, a smallish number of typically newline terminated text. However, *read* also consumes any data streamed via STDIN, including the contents of executable files.  Therefore, one can compare the contents of non-human readable files as long as there's enough memory to maintain two, potentially complete, in memory replicas.  Furthermore, the comparison function offers both regular expresssion and simple equality matching.

Equality matching performs an exact binary comparision between a newline delimited block of bytes read from \<commandExpected\> correlated to a corresponding newline delimited block of bytes read from \<commandExpected\>.  Although this uncompromising form of comparision offers a generally useful operator, it can be dynamically replaced by a regular expression comparator providing adaptive/flexible pattern matching.  To dynamically specify a regular expression comparator, the \<commandExpected\> would apply a prefix to each newline delimited byte block. This prefix triggers the comparision function to select Bash's regular expression operator ( instead of Bash's exact string match one.



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
