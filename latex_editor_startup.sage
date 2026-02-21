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
