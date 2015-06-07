using Markdown
using Color
import Compose: compose, context, polygon
using Lazy
using Gadfly

import Escher: @d

# Home page.

pkgname(name="Escher") =
    hbox(title(3, name), hskip(1em), Escher.tex("\\beta")) |> fontcolor("#999")

*(f::Function, g::Function) = x -> f(g(x))

sidenote(note, icon="info", iconcolor="#aaa") =
    hbox(Escher.icon(icon) |>
            size(100px, 100px) |>
            fontcolor(iconcolor),
        hskip(4em),
        note |>
           fontsize(0.9em) * fontcolor("#666")) |>
        pad(1em) |>
        bordercolor("#e1e1e1") |>
        Escher.borderstyle([top, bottom], solid) |>
        Escher.borderwidth([top, bottom], 1px)

function sierpinski(n)
    if n == 0
        compose(context(), polygon([(1,1), (0,1), (1/2, 0)]))
    else
        t = sierpinski(n - 1)
        compose(context(),
                (context(1/4,   0, 1/2, 1/2), t),
                (context(  0, 1/2, 1/2, 1/2), t),
                (context(1/2, 1/2, 1/2, 1/2), t))
    end
end

nᵗ = Input(5) # The angle at any given time
connected_slider = subscribe(slider(0:7, value=5), nᵗ)

reactive_eg = lift(nᵗ) do n
    vbox(
        connected_slider,
        sierpinski(n)
    )
end

tex_eg = """f(x) = \\int_{-\\infty}^\\infty
    \\hat f(\\xi)\,e^{2 \\pi i \\xi x}
    \\,d\\xi
"""
md_example = md"""**Things to do:**

- Create *universe*
- Make a *pie*
"""

part1 = md"""

$(vskip(1em))
$(

vbox(
hline(color=color("#e1e1e1")),
vskip(2em),
Escher.fontsize(2em,
     "Escher lets you build beautiful interactive Web UIs in Julia.") |>
        textalign(centertext) |>
        fontweight(200) |>
        lineheight(1.2em) |>
        maxwidth(15em) |>
        x -> hbox(flex(), x, flex()),
vskip(2em),
hline(color=color("#e1e1e1")),
)
)
$(vskip(3em))

$(title(2, "What's inside") |> Escher.fontsize(1.75em))

$(
vbox(md"**A web server for 2015.** Escher's built-in web server allows you to create interactive UIs with very little code. It takes care of messaging between Julia and the browser under-the-hood. It can also hot-load code: you can see your UI evolve as you save your changes to it.",

md"**A rich functional library of UI components.** the built-in library functions support Markdown, Input widgets, TeX-style Layouts, Styling, TeX, Code, Behaviors, Tabs, Menus, Slideshows, Plots (via [Gadfly](http://gadfly.org)) and Vector Graphics (via [Compose](http://composejl.org)) -- everything a Julia programmer would need to effectively visualize data or to create user-facing GUIs. The API comprehensively covers features from HTML and CSS, and also provides advanced features. Its user merely needs to know how to write code in Julia."
) |> pad([left, right], 2em)
)

$(vskip(2em))

# Installation

In a Julia REPL, run:

```julia
Pkg.add("Escher")
```

You might want to link escher executable to `/usr/local/bin` so that it goes in your PATH.

```sh
ln -s ~/.julia/v0.4/Escher/bin/escher /usr/local/bin/
```

# Usage

From the directory from which you want to serve files containing Escher UIs, run:

```
<Escher-package-path/bin>/escher --serve
```


From the `examples/` directory in `~/.julia/v0.3/Escher`, run the following command to bring up the escher server:


This will start a web server on port 5555. See `escher --help` for other options to this command. You can now point your browser to `http://localhost:5555/` to access the examples viewer interface. Or you can also visit `http://localhost:5555/<file>.jl` to access a specific example. `<file>.jl` could be any file inside the `examples/` directory. In general, any file with a `main` function that takes one argument-the `Window` object, and returns a valid Escher UI is served in this way.

The following section will give a general overview of how UIs are created with Escher.


# An Overview

Escher is built around 5 rules. Understanding these rules gives you a foundation to understanding Escher's comprehensive API.

## Rule 1: UIs are immutable values

A UI in Escher is simply an immutable Julia value of the abstract type `Tile`. A Tile is rendered into a browser [DOM tree](http://en.wikipedia.org/wiki/Document_Object_Model) to actually display the UI.

Escher has all kinds of functions that generate Tiles.


**Example 1.**

`plaintext("Hello, World!")` is a Tile that contains the plain text 'Hello, World!'.

To actually see this in action, create a file called `hello.jl` in an directory where the Escher server is running. Save the following code in it:

```julia
function main(window)
    plaintext("Hello, World!")
end
```

Now if you visit `http://localhost:5555/hello.jl` you should see the text "Hello, World!" on the top left corner of the screen.

$(vskip(1em))
$(sidenote(md"The function `main` *must* take a window argument, and may or may not use it. The `window` object contains some information about the current browser window. Specifically, `window.assets` is an input signal which can be used to load HTML dependencies on-the-fly. `window.alive` is a boolean signal that tells you if the window is still open. `window.dimension` is a 2-tuple representing the current size of the window in pixels."))
$(vskip(1em))

**Example 2.**

The `md""` string macro can generate markdown tiles from a markdown string.
```julia
using Markdown

function main(window)
    md\"\"\"
**Things to do:**

- Create *universe*
- Make a *pie*
    \"\"\"
end
```

*Output:*

$(md_example |> pad([left], 4em))

**Example 3.**

The `tex` function creates a TeX tile.
```julia
function main(window)
    push!(window.assets, "tex")

    tex(\"\"\"f(x) = \int_{-\infty}^\infty
        \hat f(\xi)\,e^{2 \pi i \xi x}
        \,d\xi\"\"\")
end
```
*Output:*

$(Escher.tex(tex_eg, block=true))


**Example 3.**

[Gadfly](http://gadflyjl.org) plots are essentially immutable values too. Escher type-casts Gadfly plots to tiles.

```julia
using Gadfly

function main(window)
    plot(z=(x,y) -> x*exp(-(x-int(x))^2-y^2),
         x=linspace(-8,8,150), y=linspace(-2,2,150), Geom.contour)
end
```
*Output:*

$(
plot(z=(x,y) -> x*exp(-(x-int(x))^2-y^2),
     x=linspace(-8,8,150), y=linspace(-2,2,150), Geom.contour)

)

**Example 4.**

[Compose](http://composejl.org) graphics work the same way.

```julia
using Compose
using Color

function sierpinski(n)
    if n == 0
        compose(context(), polygon([(1,1), (0,1), (1/2, 0)]))
    else
        t = sierpinski(n - 1)
        compose(context(),
                (context(1/4,   0, 1/2, 1/2), t),
                (context(  0, 1/2, 1/2, 1/2), t),
                (context(1/2, 1/2, 1/2, 1/2), t))
    end
end

main(window) = compose(sierpinski(6))

```
*Output:*

$(vskip(2em))
$(drawing(3Compose.inch, sqrt(3)/2*3Compose.inch, compose(sierpinski(6))) |> pad([left], 8em))

## Rule 2: functions that modify a tile return a *new* tile

Library functions that take tiles as input do not modify the input, they return new tiles that contain the modifications intended. This is a corollary of Rule 1, since tiles cannot be modified.

**Example 1.**

This example puts a padding of 5mm around a TeX formula, fills the tile with gray color, and changes the font color. We start off by modifying a tex tile and get a series of modified tiles which build up to the final result. Each tile is immutable and can be used later. The `vbox` function stacks many tiles vertically.

```julia
function main(window)
    push!(window.assets, "tex")

    txt = tex("T = 2\\pi\\sqrt{L\\over g}")
    txt1 = fontcolor("#499", txt)
    txt2 = pad(5mm, txt1)
    txt3 = fillcolor("#eeb", txt2)

    vbox(txt, txt1, txt2, txt3)
end
```
*Output:*

$(begin
    txt = Escher.tex("T = 2\\pi\\sqrt{L\\over g}")
    txt1 = fontcolor("#499", txt)
    txt2 = pad(5Escher.mm, txt1)
    txt3 = fillcolor("#eeb", txt2)
    vbox(txt, txt1, txt2, txt3)
end)

You can of course chain these function calls if you just want the end result.

```julia
function main(window)
    txt = tex("T = 2\\pi\\sqrt{L\\over g}")
    fillcolor("#eeb", fontcolor("#499", pad(5mm, txt)))
end
```

$(fillcolor("#eeb", fontcolor("#499", Escher.pad(5Escher.mm, Escher.tex("T = 2\\pi\\sqrt{L\\over g}")))))

## Rule 3: Escher functions have curried methods

Omitting the last tile argument to escher functions returns a 1-argument function that takes a tile.

For example, `pad(10mm)` returns an anonymous function of 1 argument which must be a tile, and that returns a new tile with the specified 10mm of padding.

Therefore, `pad(10mm, txt)` is equivalent to `pad(10mm)(txt)` or `txt |> pad(10mm)`. This is helpful when you want to apply, for example, the same padding to a all the tiles in a vector. e.g. `map(pad(10mm), [tile1, tile2])` will return a vector of two tiles with 10mm padding each.

Moreover, using the curried version with the `|>` infix operator makes for code that reads better.

**Example 1.**

The following is equivalent to the last example.

```julia
function main(window)
    tex("T = 2\\pi\\sqrt{L\\over g}") |>
        fontcolor("#499") |>
        pad(5mm) |>
        fillcolor("#eeb")
end
```

You can mentally read this as: to the plaintext Hello, World, apply font color red and then apply a padding of `10mm`.

**Example 2.**

Since the curried methods return 1-argument lambdas, they can be readily used in a call to `map` or any function that expects a 1-argument function as an argument. Here we are going to use `map` and a curried method of `pad` to pad a number of tiles.

```julia
function main(window)
    padded = map(pad([left, right], 1em), ["A", "B", "C", "D"])
    colors = ["#837", "#859", "#892", "#875"]
    tiles = map(fillcolor, colors, padded)

    hbox(intersperse(hskip(1em), tiles))
end
```

*Output:*

$(begin
    tiles = map(fillcolor, ["#837", "#859", "#892", "#875"],
        map(pad([left, right], 1em), ["A", "B", "C", "D"]))
    hbox(intersperse(hskip(1em), tiles))
end)

$(vskip(1em))

*Explanation:*

`map(pad([left, right], 1em), ["A", "B", "C", "D"])` returns a vector of 4 tiles that each have a padding of `1em` to their left and right. Note that `pad([left, right], 1em)` returns a 1-argument function, making this possible.
`map(fillcolor, colors, padded)` takes corresponding elements from the `colors` vector and `padded` vector and combines them using `fillcolor`, resulting in 4 colored tiles.  `intersperse(hskip(1em), tiles))` takes the 4-element vector `tiles` and returns a 7-element vector where `hskip(1em)` is *interspered* between each pair of adjacent tiles in `tiles`. `hskip(1em)` is simply a `1em` empty space along the horizontal axis. Finally, `hbox` puts the result of `intersperse` in a horizontal layout.

## Rule 4: layout functions combine many Tiles into one

**Example 1.**

To stack tiles vertically, use `vbox`. To stack horizontally, use `hbox`.

```julia
# Four tiles from the previous example.
a,b,c,d = map(fillcolor, ["#837", "#859", "#892", "#875"],
    map(pad([left, right], 1em), ["A", "B", "C", "D"]))

function main(window)
    x = vbox(
        a, b, c, d
    )
    y = vbox(
        d, c, b, a
    )

    hbox(x, y)
end
```

$(vskip(1em))
Should result in an arrangement like this:

$(begin
    a,b,c,d = map(fillcolor, ["#837", "#859", "#892", "#875"],
        map(pad([left, right], 1em), ["A", "B", "C", "D"]))

    x = vbox(
        a, b, c, d
    )
    y = vbox(
        d, c, b, a
    )

    hbox(x, y)
end)

`x` and `y` are vertial arrangements of 4 tiles each, these arrangements are themselves put in a `hbox` to place `x` next to `y`.


**Example 2.**

`The `tabs` function combines tiles into a set of tabs.
```julia
tabs([
    hbox(icon("face"), hskip(1em), "Tab 1"),
    hbox(icon("explore"), hskip(1em), "Tab 2"),
    hbox(icon("extension"), hskip(1em), "Tab 3"),
])
```
*Output:*
$(
tabs([
    hbox(icon("face"), hskip(1em), "Tab 1"),
    hbox(icon("explore"), hskip(1em), "Tab 2"),
    hbox(icon("extension"), hskip(1em), "Tab 3"),
])
)
$(vskip(1em))

**Example 3.**

The `pages` functions combines tiles into a set of *pages* - only a single page is visible at a time. Pages can be combined with tabs to allow switching between pages.

```julia
tabbar = tabs([
    hbox(icon("face"), hskip(1em), "Tab 1"),
    hbox(icon("explore"), hskip(1em), "Tab 2"),
    hbox(icon("extension"), hskip(1em), "Tab 3"),
])

tabcontent = pages([
    sierpinski(5),
    plot([sin, cos], 0, 25),
    title(3, "web component all the things"),
])

t, p = wire(tabbar, tabcontent, :tab_channel, :selected)
       # ^^^ returns a pair of "connected" tab set and pages
vbox(t, p)


```

$(begin

tabbar = tabs([
    hbox(icon("face"), hskip(1em), "Tab 1"),
    hbox(icon("explore"), hskip(1em), "Tab 2"),
    hbox(icon("extension"), hskip(1em), "Tab 3"),
])

tabcontent = pages([
    drawing(3Compose.inch, 3*sqrt(3)/2*Compose.inch, sierpinski(5)),
    drawing(5Compose.inch, 3Compose.inch, plot([sin, cos], 0, 25)),
    title(3, "web component all the things"),
])
t, p = wire(tabbar, tabcontent, :tab_channel, :selected)
vbox(
    t, p |> pad(1em)
) |> size(40em, 22em)
end)

Other higher-order layout functions to try are: `menu`, `submenu`, `slideshow`.

## Rule 5: An interactive UI is a Signal of UIs

[Reactive.jl](http://julialang.org/Reactive.jl) package allows "reactive programming" in Julia. Reactive programming is a style of event-driven programming with signals of data. A signal is a value that can change over time.  [Reactive.jl's documentation](http://julialang.org/Reactive.jl) provides an overview of the signal framework. At this point it is highly recommended that you read it.

There are two facets to this rule:

* Getting the input from tiles
* Creating a signal of UI using these signals

Firstly, some Tiles (particularly those that are subtypes of `Behavior` which is in turn a subtype of `Tile`) can write to Reactive's `Input` signals. Widgets such as sliders, buttons, dropdown menus are subtypes of `Behavior`. The function `subscribe` lets you pipe updates from a behavior into a signal.

**Example 1.**

Let's create a slider and subscribe its current value to a Reactive signal.

```julia

iterations = Input(0) # The angle at any given time
connected_slider = subscribe(slider(0:7), iterations)
```

*Output:*

$(slider(0:7))

`connected_slider` renders as a slider and updates the signal `iterations` when the slider's knob is moved by the user.

Secondly, you can use these input signals to create a signal of Escher UIs.

**Example 2.**

```julia

using Compose

function main(window)
    # Load HTML dependencies related to the slider
    push!(window.assets, "widgets")

    angleᵗ = Input(5) # The angle at any given time
    connected_slider = subscribe(slider(0:7, value=5), angleᵗ)

    lift(iterations) do n
        vbox(
            connected_slider,
            sierpinski(n)
        )
    end
end
```
"""

part2 = md""

include("helpers/page.jl")
function main(window)
    push!(window.assets, "widgets")
    push!(window.assets, "tex")
    push!(window.assets, "codemirror")
    push!(window.assets, "layout2")

    lift(reactive_eg) do example
        vbox(
            pkgname(),
            vskip(1em),
            part1,
            example,
        ) |> docpage
    end
end
