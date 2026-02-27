from IPython.core.magic import register_cell_magic
from pathlib import Path
from sage.repl.preparse import preparse_file_named, preparse_file   
from sage.misc.latex_standalone import Standalone
from sage.misc.latex import pdf, png


fn = get_remote_file("https://github.com/josephwright/luatex85/archive/refs/tags/v1.0.zip", verbose = False)

__tmp__ = !unzip -o {fn} -d ~/texmf/tex/latex
__tmp__ = get_ipython().run_cell_magic("script", "bash", """
cd ~/texmf/tex/latex/luatex85-1.0
latex luatex85.ins > /dev/null2&1
""");

latex.add_to_preamble( get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/preamble.tex").read_text() )

@register_cell_magic
def quick_latex(line, cell):
    """
    IT TAKES A FILENAME (just the base), A DOCUMENTCLASS (IF "standalone", do normal behaviour) AND THEN A DICTIONARY (if not present, it defaults to globals())
    """
    line = line.split()
    f = line[0]
    try:
        full = (line[1].lower() != "standalone")
    except BaseException:
        full = "standalone"
    try:
        line_locals = dict(line[2])
    except BaseException:
        line_locals = globals()
    s = cell
    if full:
        png(
            rf"""
\documentclass{{{line[1]}}}
            """ + latex.extra_preamble()
                + "\n"
                + s,
            f + ".png",
            engine = "pdflatex",
            density = 430
        );
        display(html( f" <img src='{f}.png'> " ))
    else:
        t = Standalone(s, use_sage_preamble = True)
        raw_path_to_tex = t.tex(f + ".tex")

        !pdflatex -draftmode -interaction=batchmode {f}.tex
        try:
            sage_file = Path(f"{f}.sagetex.sage")
            cmd = preparse_file(sage_file.read_text(), line_locals)
            exec(cmd)
        except BaseException:
            print("file \'%s.sagetex.sage\' not found or failed to run."%f)
        !pdflatex -interaction=batchmode {f}.tex
        !pdf2svg {f}.pdf {f}.svg 1

    display(html(f" <h2> {f}.tex </h2> <img src='cell://{f}.svg' style='display:block'> "))
