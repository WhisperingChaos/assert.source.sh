# assert.source.sh
Provide common assertion library for testing.

### Public API

#### assert_true \<bashTestEncapsulted\>
Generate message indicating failure of affirmed condition when **\<bashTestEncapsulated\>** evaluates to *false*.  Otherwise, be silent.

  - **\<bashTestEncapsulated\>**





#### assert_false \<bashTest\>
Negated form of *assert_true*

#### assert_output_true \<commandExpected\> [\<argList\>] [ <\inputDelim\> \<command_Generate\> [<arglist] ]

#### assert_output_false \<command\> [\<argList\>]
Negated form of *assert_output_true*.

#### assert_halt

#### assert_continue

#### assert_return_code_set

### References

[lehmannro/assert.sh](https://github.com/lehmannro/assert.sh)
