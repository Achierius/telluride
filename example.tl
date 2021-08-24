% this is a native comment >>> << & && ^      % Test comments
( ) { } [ ] , . : ; + * ^ ? ~ _               % Test lookahead-1 tokens
- -> / // & && | || ! != = == => < <= <<<     % Test lookahead-2 tokens
> >= >> >>>                                   % Test lookahead-3 tokens
12312 0x1A2d 0xA 0xAA 0xAAA 0b10101 0101000 0 % Test ints
"string: no parse <>" "comments bad %asd"     % Test strings
if false then true elif struct else union     % Test keywords
return execute let or print and switch case   % "    "
f fals fal e eli els elsee elife ex s         % Test near-keyword identifiers
if (x == 0 && y >= 0) then y = !x else y = 0; % Generic test
                                              % Test that end-of-file comments work now