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
Compares the output, produced by \<commandGenerate\> to the output produced by \<commandExpected\>.  The first comparison failue between these outputs produces a message.  Otherwise, be silent (all outputs match).  Comparison failures include situations where one command produces more output than the other one.

The comparision function uses the Bash *read* command to consume the output produced by both commands which populate an environment variable.   This function offers two comparision operators 

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
