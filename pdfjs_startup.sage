from pathlib import Path

_ = !unzip {get_remote_file("https://github.com/mozilla/pdf.js/releases/download/v5.5.207/pdfjs-5.5.207-dist.zip", verbose = False)}
css = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/viewer.css", verbose = False)
# mjs = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/viewer.mjs", verbose = False)
# my_file = get_remote_file("https://raw.githubusercontent.com/NathanAyre/storage/refs/heads/main/my_file.js", verbose = False)

r'''
# new my_file handling
Path("web/viewer.html").write_text(
    Path("web/viewer.html").read_text()
    .replace("</body>", f"""
    <script>
    {my_file.read_text().replace("}", "},300")}
    </script>
    </body>
    """)
)
'''
# new mjs handling
mjs = Path("web/viewer.mjs")
lines = mjs.read_text().splitlines()
replacements = r'''
const DEFAULT_SCALE_VALUE = "auto";
const DEFAULT_SCALE = 1.0;
const DEFAULT_SCALE_DELTA = 1.1;
const MIN_SCALE = 0.1;
const MAX_SCALE = 100.0;
const UNKNOWN_SCALE = 0;
const MAX_AUTO_SCALE = 10;
'''.strip().splitlines();
for i in range(len(lines)):
    if "const DEFAULT_SCALE_VALUE" in lines[i]:
        for index in [0,..,6]:
            lines[index+i] = replacements[index]
        break
    #elif "enableScripting = false" in lines[i]:
        #lines[i] = lines[i].replace("false", "true")

mjs.write_text(
    "\n".join(lines)
);

# new css handling
Path("web/viewer.css").write_text("")
Path("web/viewer.html").write_text(
    Path("web/viewer.html").read_text().replace(
        '<link rel="stylesheet" href="viewer.css" />',
        f"<style>{css.read_text()}</style>"
    )
);
