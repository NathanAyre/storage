!rm -rf folder
from pathlib import Path

startup = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/latex_editor_startup.sage")
latex_editor = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/latex_editor_cell_magic.sage")

await get_ipython().run_cell_async( Path(startup).read_text() )
await get_ipython().run_cell_async( Path(latex_editor).read_text() )

from sage.repl.ipython_kernel.widgets import * # EvalTextarea
from IPython.core.interactiveshell import InteractiveShell as IS
from ipykernel.zmqshell import ZMQInteractiveShell as ZMQ
from sage.repl.preparse import *
iframe = html.iframe

def prepare_sage_for_js(raw_sage_code):
    # 1. Strip the literals
    # stripped: "print(%(S1)s)"
    # literals: {"S1": "'hello `world`'"}
    stripped, literals, uhh = strip_string_literals(raw_sage_code)

    processed_literals = {}

    for key, value in literals.items():
        # Escape backslashes first, then escape backticks
        # This prevents JS from interpreting them as template placeholders
        safe_val = value.replace('\\', '\\\\').replace('`', '\\`').replace('$', '\\$')
        processed_literals[key] = safe_val

    # 2. Re-insert the "safe" literals back into the stripped string
    # We use Python's % operator to fill the %(L1)s placeholders
    final_sage_code = stripped % processed_literals

    return final_sage_code


# implicit_multiplication(True)

start = Path("file.sage")
# starting_string = '#print "hi"\nfrom IPython.core.interactiveshell import InteractiveShell\nIS = InteractiveShell\n\nfrom ipykernel.zmqshell import ZMQInteractiveShell as ZMQ\n\nget_ipython().run_cell_magic("writefile", "test.sage", preparse("16.sqrt()"))\nimplicit_multiplication(True)\na = 3\n\nInteractiveShell.ast_node_interactivity = "all"\nIS.ast_node_interactivity = "all"\nZMQ.ast_node_interactivity = "all"\nget_ipython().ast_node_interactivity = "all"\n\n\n# help(type(get_ipython()))\n\nfrom sage.repl.interpreter import *\nfrom ipykernel.zmqshell import ZMQInteractiveShell as ZMQ\n\n\n\nfrom sage.repl.preparse import *\nfor attr in "ipython_dir", "profile_dir":\n    # attr = attr.strip()\n    get_ipython().run_cell(preparse(r\'\'\'\n    attr\n    \'\'\'))\nshell = ZMQ()\n\n# shell.user_ns = get_ipython().user_ns\n\n\nsave_session("testing123")\n\nget_ipython(), shell\n\ns = preparse_file(# "load(\\"testing123\\")\\n" +\n                  "!ls --all\\n16"\n)\n\nshell.run_cell(s)\nprint()\n\npath = "/home/sc_serv/sage/src/sage_docbuild/__main__.py"\n\npretty = !pygmentize -f latex -O=full,style=emacs $path\n\nname = path.split("/")[-1].split(".")[0]\n/print name\n\n!ls --all $path\n\nget_ipython().run_cell_magic("writefile", name+".tex", pretty.n)\n__tmp__ = !pdflatex -interaction=batchmode $name\n!pdf2svg {name}.pdf {name}.svg\ndisplay(html.iframe(f"cell://{name}.svg"))\n\nfrom pygments.styles import STYLE_MAP\ncols = list(STYLE_MAP.keys())\n\n[str(x) for x in cols]\n\n# because len(cols) is 49, i can have a 7 by 7 matrix\ncols = matrix(SR, 7, cols)\n\nt = table(columns = cols)\n\nprint(t)\n\nshell.run_cell(r\'\'\'\nx=1\ny=3\nz=x+y\nprint x\na=5\nprint \'x\',x,\'y\',y\n%macro my_macro 1-4 6\'\'\');'
# starting_string = "from IPython.core.interactiveshell import InteractiveShell\nInteractiveShell.ast_node_interactivity='all'\n1\n2\n3\n4\n5\nfactorial(9)\n\n# more here"
starting_string = start.read_text() if start.exists() else r'''
%%latex_editor hi
%!tex nopreamble

\documentclass{article}
\usepackage{sagetex}

\begin{document}
hi. something something...

Also, did you know that $9!$ is equal to \sage{factorial(9)}? That's cool!!!! :D
\[
\int_0^{\frac94 \pi} \sin{x} \cos{x} \dd{x} = \sage{integrate(sin(x) * cos(x), x, 0, 9/4*pi)}
\]

\end{document}
'''

@interact
def silly(t = input_box(starting_string, type=str, height=10)):
    !rm -rf folder

    Path("file.sage").write_text(t)
   
    # with open("file.sage.py", "w") as f:
    #     preparse_file_named_to_stream("file.sage", f)
   
   
    # hide = ["fullScreen", "evalButton", "done"]
    hide = [
        # "editor",
        "fullScreen", "language",
        "evalButton", "permalink",
        "output", "done", "sessionFiles"
    ];
   
    js_code = 'sagecell.makeSagecell({\ninputLocation: \'pre.my_sage\',\nlanguages: sagecell.allLanguages,\nautoeval: true,\nhide: '+str(hide)+',\ncode: `' + prepare_sage_for_js(t) + '`,\ninteracts: JSON.parse(decodeURIComponent(\'%5B%5D\')),\n\n\ndefaultLanguage: \'sage\',\n\n//Focus the editor\n});\n'
   
    # save_session("hi")
    # session_code = load("hi.sobj")
   
    # exec(preparse_file(t, get_ipython().user_ns | session_code))
   
    # below is evidence that you can give the other cells your context, WITHOUT "linking" them - they still run asyncronously!!! YIPPEE!!!
    # t = "get_ipython().user_ns = get_ipython().user_ns | " + str(session_code) + "\n" + str(t) + "\n\nprint(hide)"
   
    # pyg_stdout = !pygmentize -f html -O full,style=monokai,linenos -o file.html file.sage
    # display(html(
#         r'''
# <iframe style="height: 20em; width:90vw; overflow: auto;" src="cell://file.html">
# </iframe>
# '''
    # ));
   
    display(html("<a href='cell://backup.zip'>BACKUP.ZIP</a>"))

    IS.ast_node_interactivity = "all"
    get_ipython().run_cell("%autocall 1")
   
    get_ipython().run_cell(Path("file.sage").read_text())
   
    def display_cells(num_of_cells):
        for i in range(num_of_cells):
            display(
                html(f"<pre class='my_sage'></pre>"),
                html.iframe("cell://file.sage.py"),
            )
   
    # display_cells(1)
   
    # CANCELLING THE STUFF BELOW WITH A RETURN

    %mkdir folder
   
    files = !find . -type d -name "folder" -prune -o ! -name "*.svg" -type f -print
    for f in files:
        !cp -r {f} ./folder
   
    import shutil
    import base64
   
    shutil.make_archive("backup", "zip", "./folder")

    with open("backup.zip", "rb") as f:
        data = base64.b64encode(f.read()).decode()

    display(html(f"""
<script>
(function() {{
    var scriptTag = document.currentScript;
    var sagetex = scriptTag.closest("sagetex");
    if (!sagetex || !sagetex.id) return;

    window.parent.postMessage({{
        type: "sage_backup",
        payload: "{data}",
        cell_id: sagetex.id
    }}, "*");

    console.log("hi");
}})();
</script>
"""))

    display(html(f'<div class="message" style="display:none; visibility:hidden">{data}</div>'))
# style='font-family: consolas; max-width: 50vw; max-height: 15em;overflow:clip; text-wrap:anywhere; word-wrap:anywhere'>{data}</div>"))

    !rm backup.zip

    return;

    import time
    get_ipython().run_cell_magic("javascript", "", """
        document.images.forEach(img => {
            var baseUrl = img.src.split('?')[0];
            img.src = baseUrl + '?t=' + %s;
        });

        document.querySelectorAll("iframe").forEach(iframe => {
            var baseUrl = iframe.src.split('?')[0];
            iframe.src = baseUrl + '?t=' + %s;
        });
    """%(time.time(), time.time()));
    # get_ipython().run_cell_magic("javascript", "", f"""
    # //window.parent.postMessage
    # console.log({{
    #     type: "sage_file",
    #     name: "file.sage",
    #     content: "{data}"
    # }}, "*");
    # """)
   
    # get_ipython().run_cell_magic("javascript", "", js_code)
