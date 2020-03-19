This project is a translation from C++ to OCaml of the
[breakout tutorial](https://learnopengl.com/In-Practice/2D-Game/Breakout)
at [learnopengl.com](https://learnopengl.com/). The tutorial is a
creation of [Joey de Vries](https://joeydevries.com). All the textures and audio are
directly copied from the tutorial and belong to Joey de Vries, I only collected them here so
that the code can be executed without having to look for them in their various locations.
The resulting game should be (almost) identical to what one would obtain at the end of the Render Text chapter.

I tried to reproduce as faithfully as possible the general architecture of the original C++ code,
and to use more or less the same implementations for the various game features. This would allow
someone who is interested in going through the tutorial with OCaml not to be lost
when comparing both versions. Of course it was necessary to make some changes here and there,
firstly in order to accomodate discrepancies between OCaml and C++ and maintain a reasonably functional style,
secondly because all the dependencies were not necessarily available in the OCaml ecosystem.

## Main differences from the original version
### C libraries
Wherever external C libraries were used in the original, I replaced them with an existing OCaml binding to the same
or an equivalent library if availabe. When I was not able to find something simple enough, I included homemade restricted
bindings wrapped into a small library that mimics as closely as possible what was used in the tutorial. (See the sections
below for more details.)

### Windowing
The windowing library GLFW is replaced by [SDL2](https://www.libsdl.org/), because I already used SDL for the audio anyway.
The SDL interface is accessed through the [tsdl](https://erratique.ch/logiciel/tsdl) OCaml bindings.

### OpenGL
The OpenGL functions are accessed through the [tgls](https://erratique.ch/logiciel/tgls) OCaml bindings.

### Image loading
The textures are loaded with [stb_image](https://github.com/nothings/stb) (which is what SOIL is based on).
It is accessed with a homemade binding to the `stbi_load` and `stbi_image_free` functions.

### Audio playback
The audio loading and playback is performed with [SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/), using a homemade
binding to the necessary functions.
The sound files, unlike in the tutorial, are handled by the resource manager, just like the shaders and the textures.
The high-level playback function is located in the `Resource_manager` module as well.

### Font loading
The FreeType library is replaced by [stb_truetype](https://github.com/nothings/stb), again with a homemade binding to the
necessary functions. The functionality provided is slightly different from that of FreeType, so the text rendering part
of the tutorial has some variations. Most notably, the space character is treated as a special case.

### Vectors and matrices
The GLM library is not used. Instead, the `Util` module contains (very naive) implementations of the basic vector and
matrix operations used in the tutorial, including the computation of the orthographic projection matrix. The `Util` module also
contains some other unrelated convenience functions.

### Objects and inheritance
All the objects are replaced by record types, or sometimes by modules in the case of singletons. The inheritance relationship
between the ball and the basic game object is implemented by including a game object field as part of the ball record.
As a result, the collision checking cannot be overloaded, and instead the different implementations have been divided up
into the corresponding objects' modules.

### Global variables
Several objects that were global in the C++ version become fields of the game type. This seemed like a good way to keep things functional without rearranging the structure of the code too much.

## Dependencies
- [dune](https://github.com/ocaml/dune): build system
- [base](https://opensource.janestreet.com/base/): OCaml standard library replacement
- [stdio](https://github.com/janestreet/stdio): I/O library (complement to base)
- [tgls](https://erratique.ch/logiciel/tgls): OpenGL binding for OCaml
- [SDL2](https://www.libsdl.org/): windowing, input, etc.
- [SDL_mixer](https://www.libsdl.org/projects/SDL_mixer/): audio loading and playback
- [tsdl](https://erratique.ch/logiciel/tsdl): SDL2 binding for OCaml
- [ctypes](https://github.com/ocamllabs/ocaml-ctypes): tools to generate C bindings
- [stb_image](https://github.com/nothings/stb): image loading (copy included)
- [stb_truetype](https://github.com/nothings/stb): font loading (copy included)

## Build
The stb_image and stb_truetype headers are already included in the source code. After having installed SDL2 and SDL_mixer, install the OCaml dependencies with [opam](https://opam.ocaml.org/):
```sh
opam install dune base stdio tgls tsdl ctypes
```

Then build with
```sh
dune build
```

From the root of the project, run the executable that was generated in the `_build` directory, for instance with
```sh
dune exec ./src/main.exe
```