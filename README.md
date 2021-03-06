# SpriteBuilder

SpriteBuilder is a free tool (released under MIT-licence) for rapidly developing games and apps. SpriteBuilder is built for cocos2d-iphone.

For more info and binary downloads, please visit [spritebuilder.org](http://spritebuilder.org). *(Website is not yet up!)*

## Getting started with the source

Cocos2d and other extensions are provided as a submodules to this project. To be able to compile the source code you need first check out the module. Change directory into the top (this) directory of SpriteBuilder and run:

    git clone https://github.com/apportable/SpriteBuilder
    cd SpriteBuilder
    git submodule update --init --recursive

When building SpriteBuilder, make sure that "SpriteBuilder" is the selected target (it may be some of the plug-in targets by default).

## Still having trouble compiling SpriteBuilder?

It is most likely still a problem with the submodules. Edit the .git/config file and remove the lines that are referencing submodules. Then change directory into the top directory and run:

    git submodule update --init

When building SpriteBuilder, make sure that "SpriteBuilder" is the selected target (it may be some of the plug-in targets by default).

## License (MIT)
Copyright © 2011 Viktor Lidholt

Copyright © 2012-2013 Zynga Inc.

Copyright © 2013 Apportable Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

SpriteBuilder: [http://spritebuilder.org](http://spritebuilder.org) *(Website is not yet up!)*
