# assert.source.sh
Provide yet another assertion library for testing.  Primarily for Bash scripting but can be broadly applied to CLI programs that affect environment variables or generate output.

### Public API

#### assert_true \<bashTestEncapsulted\> ["${@}"]
Generate message indicating failure of stated condition when **\<bashTestEncapsulated\>** evaluates to *false*.  Otherwise, be silent.

  * **\<bashTestEncapsulated\>** any bash [conditional expression](https://www.gnu.org/software/bash/manual/html_node/Bash-Conditional-Expressions.html) cocooned to satisfy its parser so it treats the expression as a single argument.  This delays the expression's evaluation so it can occur within the implementation of **assert_true**.
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

#### assert_output_true \<commandExpected\> [\<argList\>] [\<inputDelim\> \<command_Generate\> [\<arglist\>]]

#### assert_output_false \<command\> [\<argList\>]
Negated form of *assert_output_true*.

#### assert_halt

#### assert_continue

#### assert_return_code_set

### References

[lehmannro/assert.sh](https://github.com/lehmannro/assert.sh)
