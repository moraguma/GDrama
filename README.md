<p align="center">
  <img src="icon.png" />
</p>


# GDrama

## Writing in GDrama

GDrama is a simple language to write cutscenes. In practice, all .gdrama files are converted to a JSON format. GDrama exists to make writing scenes easier.

For instance, this is a simple scene written in GDrama.

~~~
<beat Start>
    Tom: Hey! (wait 0.5)Over here!(wave)
    Tom: This is an example scene
    Tom: [wave]What do you think?

    <choice "I like it!" Like>
    <choice "Not a huge fan" Dislike>

<beat Like>
    Tom: Well, I'm glad!
    <jump End>

<beat Dislike>
    Tom: That's a shame
    <jump End>

<beat End>
    Tom: Anyway, I have to go
    <end "Regular ending">
~~~

When converted to JSON, it will look like this

~~~json
{
    "start": "Start",
    "beats": {
        "Start": {
            "steps": {
                "0": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "Hey! (wait 0.5)Over here!(wave)"
                },
                "1": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "This is an example scene"
                },
                "2": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "[wave]What do you think?"
                },
                "3": {
                    "type": "CHOICE",
                    "choices": ["I like it!", "Not a huge fan"],
                    "results": ["Like", "Dislike"],
                    "conditions": ["{get_true}", "{get_true}"]
                }
            },
            "next": "Like"
        },
        "Like": {
            "steps": {
                "0": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "Well, I'm glad!"
                },
                "1": {
                    "type": "CALL",
                    "call": "{jump End}"
                }
            },
            "next": "Dislike"
        },
        "Dislike": {
            "steps": {
                "0": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "That's a shame"
                },
                "1": {
                    "type": "CALL",
                    "call": "{jump End}"
                }
            },
            "next": "End"
        },
        "End": {
            "steps": {
                "0": {
                    "type": "DIRECTION",
                    "actor": "Tom",
                    "direction": "Anyway, I have to go"
                },
                "1": {
                    "type": "END",
                    "info": "Regular ending"
                }
            },
            "next": ""
        }
    }
}
~~~

## Commands

GDrama uses a few special characters for its commands. If any of them must be used as part of direction, the \ character can be used before them to avoid them being detected as a command

### <> - .gdrama level commands

Commands wrapped up in <> are going to be completely processed by the time the .gdrama file is converted into a JSON

|Function|Use|
|---|---|
|\<_const_ "Const name" "Const value">| Defines a new constant|
|\<_import_ "path"| Imports constants from provided .gdrama file|
|\<_get_ "Const name">|Substituted by the constant. Can also be used as \$name or $"Const name"|
|\<_beat_ "Beat Name">|Marks the start of a new beat|
|\<_call_ {_function_ arg1, arg2...}>|Calls a DramaReader level function|
|\<_jump_ "Beat name">| Jumps to the specified beat. Is actually a DramaReader level function - equivalent to \<_call_ {jump "Beat name"}>|
|\<_choice_ "Choice text" "Resulting beat" {DramaReader condition}>|Defines a new choice with an existence condition. If no existence condition is defined, it is set as true by default|
|\<_end_ "Info">|Defines an ending|

### {} - DramaReader level commands

Commands wrapped up in {} are processed in runtime as the DramaReader encounters them. As such, they are present in the generated JSON file. These commands are direct function calls to the to_call object in the DramaReader

{_function_ arg1 arg2...}

### () - DramaAnimator level commands

Commands wrapped up in () are processed only by the DramaAnimator. As such, the returned values from the DramaReader will have these segments intact

(_function_ arg1 arg2...)

### [] - BBCode

These values will not be touched at all by GDrama. These commands can be used for injecting BBCode in direction when it is being used in conjunction with the RichTextLabel

## Copyright

Copyright/attribution is not required, though appreciated. Credit me as Moraguma and link to https://moraguma.itch.io/
