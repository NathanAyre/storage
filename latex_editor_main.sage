from textwrap import dedent
import asyncio
from IPython.core.interactiveshell import InteractiveShell

from IPython.core.magic import register_cell_magic
from pathlib import Path
from IPython import get_ipython as get_ipy
from urllib.parse import urlparse
from sage.repl.ipython_extension import SageCustomizations


async def my_run_cell_async(cmd):
    cmd = dedent(cmd)
    shell = InteractiveShell()
    o = SageCustomizations(shell)
    o.init_environment()
    o.init_inspector()
    o.init_line_transforms()
    o.register_interface_magics()
    o.run_init()
    
    shell.user_ns = shell.user_ns | globals() | locals()

    await asyncio.to_thread(shell.run_cell, cmd)

async def my_run_cells_async(cmds):
    await asyncio.gather(*(my_run_cell_async(cmd) for cmd in cmds))
    
# ---------------------

async def latex_editor_async(cmd):
    cmd = dedent(cmd)
    shell = InteractiveShell()
    o = SageCustomizations(shell)
    o.init_environment()
    o.init_inspector()
    o.init_line_transforms()
    o.register_interface_magics()
    o.run_init()
    
    shell.user_ns = shell.user_ns | globals()
    
    # i am moving "load('latex_editor_cell_magic.sage')" to the main program, so it'll end up in globals()
    # shell.run_cell( "load('latex_editor_cell_magic.sage')" )
    await asyncio.to_thread(shell.run_cell, cmd)
    
async def latex_editors_async(cmds):
    await asyncio.gather(*(latex_editor_async(cmd) for cmd in cmds))

# begin startup

# !rm -rf /home/sc_work/texmf
!mkdir /home/sc_work/texmf
if Path("/home/sc_work/texmf/tex/latex/sagetex").exists() == False:
    !cp -a /home/sc_serv/sage/venv/share/texmf/. /home/sc_work/texmf

urls = [
    "https://github.com/josephwright/siunitx/releases/download/v3.4.14/siunitx.tds.zip",
    "https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/physics.sty",
    "https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/mhchem.sty",
    "https://raw.githubusercontent.com/cgnieder/chemgreek/refs/heads/master/chemgreek.sty",
    "https://raw.githubusercontent.com/gpoore/pythontex/refs/heads/master/pythontex/pythontex.dtx",
    "https://github.com/fpantigny/piton/archive/refs/tags/v4.11.zip",
    "https://github.com/gpoore/pythontex/archive/refs/tags/v0.18.zip",
]

def process_url(url):
    from pathlib import Path
    from urllib.parse import urlparse
    from textwrap import dedent
    from IPython import get_ipython as get_ipy
    
    if isinstance(url, str):
        path = get_remote_file(url, verbose = False)
        temp_name, ext = os.path.splitext(os.path.basename(path))
        real_name = Path(urlparse(url).path).name
        p = Path("/home/sc_work/texmf/tex/latex/" + real_name)
        # print(p, p.exists())
        if p.exists(): return;
    else:
        path = get_remote_file(url[0], verbose = False)
        temp_name, ext = os.path.splitext(os.path.basename(path))
        real_name = url[1]
        p = Path("/home/sc_work/texmf/tex/latex/" + real_name)
        if p.exists(): return;
    # display(temp_name, real_name, ext)

    get_ipy().run_cell(
        dedent("""
        %%%%script bash
        mv %s /home/sc_work/texmf/tex/latex > /dev/null 2>&1        # move remote file into folder
        cd /home/sc_work > /dev/null 2>&1 # set working directory to /home/sc_work. JUST MAKING ~/texmf DOES NOT WORK! YOU NEED /home/sc_work/texmf INSTEAD!!!

        # ls --all texmf > /dev/null 2>&1     # list the contents of texmf before unzipping
        cd texmf/tex/latex > /dev/null 2>&1
        """%(path)
        + (f"unzip {temp_name} -o > /dev/null 2>&1" if ext == ".zip" else f"mv {temp_name}{ext} {real_name} > /dev/null 2>&1")
        + """
        cd # > /dev/null 2>&1                 # revert working directory: /home/sc_work/texmf -> /home/sc_work
        # ls --all texmf > /dev/null 2>&1   # list the contents of texmf after unzipping
        """)
    )

# func_path = tmp_filename()
# save(pickle_function(process_url), func_path)

await my_run_cells_async(
    dedent(f"""
    process_url('{url}')
    """) for url in urls
)

# back at home directory, I run any build files (manually D:)
try:
    build_commands = [
        r'''
        %%script bash
        cd ~/texmf/tex/latex/{location} > /dev/null 2>&1
        {command} {name}               > /dev/null 2>&1
        '''.format(command = c, location = l, name = n) for [c, l, n] in [
            # ["latex", "piton-4.11", "piton.ins"],
            # [r"""printf "3\ny" | python3""", "pythontex-0.18/pythontex", "pythontex_install.py"] if Path("~/texmf/scripts/pythontex/pythontex.py").exists() == False else None
        ]
    ]
except BaseException:
    build_commands = []

build_commands = [dedent(c) for c in build_commands]

if build_commands != []:
    await my_run_cells_async(build_commands)

# end startup

latex_cell_file = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/latex_editor_cell_magic.sage")

display(html("loading <code>latex_editor_cell_magic.sage</code>."))
load(latex_cell_file, verbose = False)

!pygmentize -f png -l python -O full,style=github-dark,font_size=16 -o latex_cell.png {latex_cell_file}

display(
    html.iframe("cell://latex_cell.png", 300, 500),
)

cmds = [
    r'''
%%latex_editor sagetex_test{}'''.format(i)
+ r'''
\usepackage{fancyvrb}

\newcounter{mysageblock}

\newenvironment{mysageblock}
{
  \stepcounter{mysageblock}
  \edef\mysagefilename{mysageblock-\themysageblock.sage}

  % Start writing verbatim to file
  \VerbatimOut{\mysagefilename}
}
{
  \endVerbatimOut

  % Now execute it
  \begin{sagesilent}
  load("\mysagefilename")
  \end{sagesilent}
  
  \par %

  % Now typeset it
  \myinput{python}{\mysagefilename}
}


\begin{document}
\begin{sageblock}
total = 0
for i in range(15):
    total += i
\end{sageblock}

$\displaystyle{\sum_{k=1}^{14} k = \sage{total}}$

Or, using this silly code:
\begin{sageblock}
k = var("k")
total = sum(k, k, 1, 14)
\end{sageblock}
it is: \sage{total}.

\vspace{1ex}

additionally, i am not using Python\Tex{} anymore. \sageplot[width=0.3\textwidth]{
    plot(
        [x^2, 8*x-3, (8*x-3)*sin(x)],
        (x, -10, 10),
        frame = True,
        gridlines = "minor"
    )
}

\pagebreak

\subsection*{Testing siunitx's rounding}
\begin{sageblock}
strings = [
    r"\num[round-mode=places, round-precision=4]{278}",
    r"\num[round-mode=figures, round-precision=5]{%s}"%(pi.n())
];

big_string = ""
for s in strings:
    s = [s, s]
    s[0] = s[0].replace("{", r"\{")
    s[0] = s[0].replace("}", r"\}")
    
    s[0] = r"\texttt{\string" + s[0] + r"}"
    
    big_string += "{0}: ${1}$ \\newline".format(*s)
    
print(big_string)
\end{sageblock}

\sagestr{big_string}

\vspace{2ex}
\num[round-mode=places, round-precision=1]{20.97}
\num[parse-numbers=false]{$20.97$}

\pagebreak

\subsection*{table for count-rate experiment - using siunitx}

\begin{sagesilent}
code = r"""
data = [
    [5.0, 405, 75],
    [10.0, 400, 207],
    [15.0, 400, 389],
    [20.0, 200, 275]
];

[row.insert(1, row[0] - 0.5) for row in data]
[row.insert(2, 0.5) for row in data]

# data = matrix(data).transpose()

# data[-1] = [round(x) for x in data[-1]]
# for i in [2]:
#     data[i] = [x.n(digits = 2) for x in data[i]]

# for i in [0,1]:
#     data[i] = [round(314.8997, 3) for x in data[i]]

# data = list(data.transpose())


t = table(
    rows = data,
    header_row = [r"$r=x+d$ / cm", r"$x$ / cm", r"$d$ / cm", r"counts", r"time / s", r""],
    frame = True
); show(t)

# NOW HERE'S THE SIUNITX ROUNDING APPLIED:

latex_t = latex(t).splitlines()
display(html("<h2>ORIGINAL</h2>"), latex_t)


display(
    html("<hr>"),
    [row.split(r"\\") for row in latex_t],
    html("<hr>")
); latex_t = [row.split(r"\\") for row in latex_t]



latex_t[1][0] = " & ".join(["{%s}"%header for header in latex_t[1][0].split("&") ])

for row_index in range(1, len(latex_t) - 1):
    latex_t[row_index][0] = [(x.replace("$", "") if row_index != 1 else x) for x in latex_t[row_index][0].split("&") ]

for column_index in range(3):
    for row_index in range(2, len(latex_t) - 1):
        row = latex_t[row_index][0]
        
        row[column_index] = r"\num[round-mode=places, round-precision=1]{%s}"%(row[column_index])

display(latex_t)

# FINSIH LATER. THIS IS GOOD!
for row_index in range(1, len(latex_t) - 1):
    latex_t[row_index] = " & ".join(
        flatten( latex_t[row_index] ) # flattened because each row isn't 1D: [ [col1, col2, ...], ['\\hline'] ]
    )
    
print("\n\n")

# i can replace latex_t[0][0] with my own column definitions, because i might wanna try out the siunitx `S[]` columns
latex_t = latex_t[0][0] + "\n \\\\ \n".join(flatten(latex_t[1:])) # another flatten is required.

print(latex_t)"""

from textwrap import dedent
code = dedent(code).strip()

with open("count_rate.sage", "w") as file:
    file.write(code)
    
load("count_rate.sage")
\end{sagesilent}

% now, printing the file contents
\begin{sagesilent}
with open("count_rate.sage", "r") as f:
    lines = f.read()
    display(lines)
\end{sagesilent}

\sagestr{latex_t}

\myinput{python}{count_rate.sage}

\pagebreak

% \begin{mysageblock}
% display(html("<h1>IT IS WORKING!!! YAYYYYYYY</h1>"))
% \end{mysageblock}

\end{document}
    ''' for i in [
            "1_",
            # "2_",
            # "3_"
        ]
]

for i in range(10):
    test_cmd = r"""
    %%latex_editor sagetex_async%s
    \documentclass{article}
    \begin{document}

    \section*{This is \texttt{sagetex\_async%s.tex}}

    \sage{factorial(9)}

    \begin{sagesilent}
    x = var("x")
    f(x) = %s*sin(x)
    \end{sagesilent}

    \sageplot{
        plot([f(x), x^(%s)], x, -1, 1, legend_label = "automatic")
    }
    
    \end{document}
    """.replace("%s", str(i));
    
    # cmds.append(test_cmd)
    
# await latex_editors_async(cmds)
