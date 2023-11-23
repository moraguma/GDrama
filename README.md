<p align="center">
  <img src="icon.png" />
</p>


# GDrama
GDrama is a simple framework for writing cutscenes in Godot. It supports a bunch of features that you might expect from any game that includes dialogue, such as choices, dialogue boxes and character animations! This addon was made to provide a base from which a developer may create their cutscene system considering the particular needs of their game

<p align="center">
  <img src="example.png" />
</p>

## Writing in GDrama

The GDrama language is used to write cutscenes. It is meant to resemble a screenplay! Here's what a simple dialogue looks like

![You can read this in dramas/example.gdrama](gdrama.png)

```mermaid
graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
```

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
