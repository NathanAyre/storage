from IPython.core.magic import register_cell_magic
from IPython.core.interactiveshell import InteractiveShell
from pathlib import Path
from IPython import get_ipython as get_ipy
from urllib.parse import urlparse
from textwrap import dedent
from sage.repl.ipython_extension import SageCustomizations

import asyncio
# import nest_asyncio
# nest_asyncio.apply()

@register_cell_magic
def latex_editor(line,
                 cell = r"""
                    \documentclass{article}
                    \begin{document}
                    Compare the following:

                    \begin{array}{r<{ {:} } @{ \ } l}
                        \verb!\qty{35000e-3}{\newton}! & \qty{35000e-3}{\newton}
                        \\
                        \verb!\qty[evaluate-expression=true]{35000e-3}{\newton}! & \qty[evaluate-expression=true]{35000e-3}{\newton}
                    \end{array}
                   
                    \end{document}"""
                ):
    display(html("<h3>STARTING!</h3>"))
    __tmp__ = !rm *.svg
    filename = line
    preamble = r"""
  \documentclass{article}
  % PACKAGES TO ADD
  \usepackage{sagetex}
  \usepackage{etoolbox}
  % \AtEndPreamble{\usepackage{pythontex} \setpythontexlistingenv{pylisting}}
  %\usepackage{piton} %!NOtex lualatex
 
 
  \usepackage{amsmath}
  \usepackage{float}
  %\usepackage{fontspec}
  \usepackage[utf8]{inputenc}
  \usepackage{fancyvrb, fvextra, xstring, pgfopts, newfloat, currfile}
  \usepackage{amssymb}
  \usepackage{array}
  \usepackage{mathtools}
  \usepackage{siunitx}
  \usepackage{tikz}
  \usepackage{tikz-3dplot}
  \usepackage[european, cute inductors, straight voltages, siunitx]{circuitikz}
  \usetikzlibrary{shapes.geometric, arrows, decorations.markings}
  \usepackage{graphicx, caption, hyperref}
  \usepackage[export]{adjustbox}
  \usepackage{wrapfig}
  \usepackage{subcaption}
  \usepackage{titlesec}
  \usepackage{physics}
  \usepackage{lipsum}
  % \usepackage[a4paper, left=1cm, right=1cm, top=2cm]{geometry}
  \usepackage[version=4]{mhchem}
  \usepackage[most]{tcolorbox}
  \usepackage{enumitem}
  \usepackage{empheq}
  \usepackage{tasks}
  \usepackage{changepage} % for adjustwidth
  \usepackage{listings}
  \usepackage{minted}
  \usepackage[dvipsnames]{xcolor}
  % \usepackage{inconsolata} % NOT AVALIABLE ON SAGEMATHCELL
  \usepackage{cancel}
  \tcbuselibrary{minted,skins,breakable,hooks}
  \usepackage{pgfplots}
  \usepackage{mathrsfs}
  \usetikzlibrary{arrows}
  % \pagenumbering{gobble}
 
    \usepackage{accsupp}

    \renewcommand{\theFancyVerbLine}{%
        \rmfamily\tiny\bfseries\textcolor{White}{%
            \BeginAccSupp{method=escape,ActualText={}}%
                \arabic{FancyVerbLine}%
            \EndAccSupp{}%
        }%
        \hss% This trailing glue is here to balance the leading \hss in \FV@Numbers@left (fancyvrb.sty), which by default right-aligns the number; This makes the numbers horizontally centered within the fixed-width box reserved for line numbers
    }

    \newcommand{\hboxNumberFormat}{%
        \def\FancyVerbFormatLine##1{%
            \hspace{-1mm}% I was using '\csname FV@XLeftMargin\endcsname - \csname FV@NumberSep\endcsname', but it no longer works in this MWE        
            \makebox[\csname FV@NumberSep\endcsname][c]{%
                \theFancyVerbLine%
                \unskip% To negate the effect of the \hss added in the \theFancyVerbLine redefinition above
            }%
            ##1%
        }%
    }
   
    \tcbset{
      myCodeBase/.style={
        skin=enhanced,
        drop fuzzy shadow=Gray,
        coltitle=White,
        colbacktitle=Black!85,
        colframe=Black!85,
        colback=Gray!15,
        boxrule=0.2pt,
        boxsep=0pt,
        left=2mm,
        right=2mm,
        fonttitle=\ttfamily\bfseries,
        toptitle=1mm,
        bottomtitle=1mm,
        titlerule=0pt,
        listing only,
        listing engine=minted,
        minted style=staroffice,
        minted options={
          mathescape,
          autogobble,
          escapeinside=||,
          fontsize=\footnotesize,
          fontfamily=tt,
          ignorelexererrors=true,
          samepage=false
        }
      }
    }


    \NewTCBListing{myCodeBlock}{ s O{} m t* }{%
        #2,%
        minted language=#3,%
        myCodeBase,%
        IfBooleanTF={#1}{%
            breakable,% If the box is larger than the available space at the current page, the box is automatically broken and continued to the next page
            % before upper={},% The given ⟨code⟩is placed after the color and font settings and before the content of the upper part
            minted options app={% Appends the given options to 'minted options'
                % numberblanklines=false,%
                breaklines,% Automatically break long lines in code blocks and wrap longer lines in \mintinline (breaks at spaces by default)
                breakanywhere% Allow line breaks anywhere, not just at spaces
            }%
        }{%
            capture=hbox,% Defines how the box content is processed
            center% Enlarges the bounding box equally to both sides to fill the line completely
        },%
        IfBooleanF={#4}{%
            left=0mm,%
            lefttitle=5mm,% Sets the left space between title text and frame (additional to boxsep)
            minted options app={
                numbersep=5.5mm,% Gap between numbers and start of line
                xleftmargin=\dimexpr4mm+2pt\relax,% Indentation to add before the listing
            },%
            IfBooleanTF={#1}{%
                minted options app={%
                    linenos% specify that the lines should be numbered
                }%
            }{%
                minted options app={%
                    formatcom=\hboxNumberFormat%
                }%
            },%
            overlay={% Adds graphical code to the box drawing process. This graphical code is drawn after the frame and interior and before the text content.
                \begin{tcbclipinterior}%
                    \fill[Black!85](frame.south west)rectangle([xshift=4mm]frame.north west);%
                \end{tcbclipinterior}%
            }%
        }%
    }
   
    \newtcbinputlisting{\myinput}[3][]{
      myCodeBase,
      minted language=#2,
      listing file={#3},
      #1,
      left=0mm,
      breakable,
      lefttitle=5mm,
      minted options app={
        numbersep=5.5mm,
        xleftmargin=\dimexpr4mm+2pt\relax,
        breaklines,
        breakanywhere
      },
      minted options app={linenos},
      overlay={
        \begin{tcbclipinterior}
          \fill[Black!85](frame.south west)
            rectangle([xshift=4mm]frame.north west);
        \end{tcbclipinterior}
      }
    }

 
  \titlespacing\section{0pt}{12pt plus 4pt minus 2pt}{0pt plus 2pt minus 2pt}
  \titlespacing\subsection{0pt}{12pt plus 4pt minus 2pt}{0pt plus 2pt minus 2pt}
  \titlespacing\subsubsection{0pt}{12pt plus 4pt minus 2pt}{0pt plus 2pt minus 2pt}

  \setlength{\parindent}{0px}
  \setlength{\parskip}{1ex}
  \makeatletter
  \newcommand\@minipagerestore{\setlength\parindent{0px}\setlength\parskip{1ex}\raggedright}
  \makeatother
  % replace 1ex in the parskip with \baselineskip if i want it to match the default setting (which may not be 1ex)

  % \AtBeginDocument{\RenewCommandCopy{\qty}{\SI}}

  \pgfplotsset{compat=1.18}

  \definecolor{wwzzqq}{rgb}{0.4,0.6,0}
  \definecolor{wwccqq}{rgb}{0.4,0.6,0}
  \definecolor{ffqqqq}{rgb}{1,0,0}
  \definecolor{dtsfsf}{rgb}{0.8274509803921568,0.1843137254901961,0.1843137254901961}

  % i removed python stuff. i should just use \usepackage{pythontex} with PDFLaTeX (or whatever) in -shell-escape mode. :D

  % cools!!!
  \newcommand{\n}{\\[1ex]} % nicer spacing
  \newcommand{\tdots}{{\text{...} \,}} % text dots for truncation
  \newcommand{\dscript}{\displaystyle \scriptsize} % to allow display spacing rules in script areas
  \newcommand{\ddv}[2]{\displaystyle \dv{#1}{#2}}
  \newcommand{\result}[3]{\mskip{#1} \boxed{ \begin{alignedat}{#2} #3 \end{alignedat} }} % use similarly to \center. THIS IS AN ALIGNEDAT!!!!!

  \newcommand{\dn}{\n \displaystyle}
  \newcommand{\an}{\n & \displaystyle} % use for new lines in a \colarray
  \newcommand{\qan}{\n & \displaystyle \quad} %version for use in \qcolarray where there is quad spacing!
  \newcommand{\col}{& \displaystyle} % column break in displaystyle :D

  \newcommand{\colarray}[3]{\begin{array}#1 \displaystyle #2 & \displaystyle #3 \end{array}} %dont forget to add new & characters on new lines when inputting data for #3! brilliant for two-column layouts.

  \newcommand{\qcolarray}[1]{\quad \colarray{[t]{l|l}}{}{\quad #1}} % "q" for "quick" and "quad"
  \newcommand{\qcolarrayAligned}[3]{\quad \colarray{[t]{l|l}}{\begin{aligned}[#1] \quad #2 \end{aligned}}{\begin{aligned}[#1] \quad #3 \end{aligned}}}

  \newcommand{\sub}[1]{_{\text{#1}}}

  \newcommand{\SUVAT}[6]{\mskip3em \begin{alignedat}{2} %First 5 are values, the 6th is for spacing
  &s\colon && #6 {#1}
  \\
  &u\colon && #6 {#2}
  \\
  &v\colon && #6 {#3}
  \\
  &a\colon && #6 {#4}
  \\
  &t\colon && #6 {#5}
  \end{alignedat}}

  \newcommand{\step}[2]{\hphantom{\textbf{#1} \ } \ #2 \\[1ex]}
  \newcommand{\qstep}[2]{\\[2ex] \step{#1}{#2}}
  \newcommand{\pstep}[3]{\hphantom{\textbf{#1 #2}} \ #3 \\[1ex]}
  \newcommand{\qpstep}[3]{\\[2ex] \pstep{#1}{#2}{#3}}

  \renewcommand{\part}[2]{\textbf{#1} \ #2 \\[1ex]}
  \newcommand{\qpart}[2]{\\[2ex] \part{#1}{#2}}
  \newcommand{\ppart}[3]{\hphantom{\textbf{#1}} \ \textbf{#2} \ #3 \\[1ex]}
  \newcommand{\qppart}[3]{\\[2ex] \ppart{#1}{#2}{#3}}

  \newcommand{\lfrac}[2]{\left. #1 \middle/ #2 \right.}
  \newcommand{\vln}[1]{\ln\vqty{#1}}
  \newcommand{\point}[2]{\pqty{{#1}\text{, } {#2}}}
  \newcommand{\QED}{\qquad \blacksquare}
  \newcommand{\degree}{^{\circ}}
  \newcommand{\desc}[1]{\ \text{#1}}
  \newcommand{\exptall}{\vphantom{\underset{a}{b}}}
  \newcommand{\nexptall}{\vphantom{\overset{a}{b}}}
  \newcommand{\tall}{\vphantom{\dfrac11}}
  \newcommand{\Tall}{\vphantom{\frac {\dfrac 11} {a} }}

  \newtcolorbox{mybox}[1]{colback=red!5!white,colframe=red!75!black, fonttitle=\bfseries, title={#1}}

  % For \tcbhighmath
  \tcbset{highlight math style={enhanced,
  colframe=red!60!black,colback=yellow!50!white,arc=4pt,boxrule=1pt,
  drop fuzzy shadow, left = 3px}}

  % For any multiline \tcbhighmath that need alignment or separate equation numbering

  % \begin{empheq}[box=\tcbhighmath]{align}
  % a&=\sin(z)\\
  % E&=mc^2 + \int_a^b x\, dx
  % \end{empheq}



  % Only use for answers to multiple-part Qs (use \multicols)
  \newtcolorbox{answer}[1]{after title = {\hfill \colorbox{white!100}{\textcolor{black}{Answer}}}, colframe=red!75!black, fonttitle=\bfseries, title={#1}, breakable}

  % Brilliant for examples!
  \newtcolorbox{example}[1]{after title = {\hfill \colorbox{red!75!black}{Example(s)}}, colback=green!5!white,colframe=green!35!black, sharpish corners, fonttitle=\bfseries, title={#1}, breakable}

  % The cleanest box; for definitions, proof and notes!
  \newtcolorbox{clean}[2]{after title = {\hfill \colorbox{orange!85}{#2}}, colback=black,colframe=gray, coltext = white, sharpish corners, fonttitle=\bfseries, title={#1}, breakable}

  % Clean info box (green only lines, white back)
  \newtcolorbox{info}[1]{colback = white, colframe = green!65!black, fonttitle=\bfseries, title = {\centering #1}, breakable}

  % Use \tcblower for single-answers to single-questions
  \newtcolorbox{question}[1]{after title = {\hfill \colorbox{black}{Question(s)}}, colback=white, colframe=blue!75!black, fonttitle=\bfseries, title={#1}, breakable}

  \pgfplotsset{
  point/.style={
  only marks,
  mark=*,
  color=blue,
  mark size=2pt,
  }
  }

  % \vb{a}
  % \va{a}

  % \qty(\typical)
  % \qty(\tall)
  % \qty(\grande)

  % \qty[\typical]
  % \qty|\typical| etc

  % \qty\big{}, \qty\Big{}, \qty\Bigg{}

  % OR !!!

  % \pqty{}, \bqty{}, \vqty{}, \Bqty{}



  % TRIG

  % \sin() should have auto bracing
  % \sin(\grande)
  % \sin[2](x)

  % They exist for \ln(), \exp(), and \log()


  % \real and \imaginary for the funny symbols now

  % \qq{} puts \quad either side of text
  % \qq*{} only has right \quad

  % \dd{x} has auto spacing either side
  % \dd[3]{x} has optional power
  % \dd() has auto braces

  % \dv[3]{f}{x} has optional power
  % \dv{x}{\grande}
  % \dv*{f}{x} is inline using \flatfrac

  % \begin{pmatrix}
  % \imat{2} \\ a & b
  % \end{pmatrix}

  %you can use \mqty to make \imat{2} into a single matrix element of a larger matrix:

  % \begin{pmatrix}
  % \mqty{\imat{2}} & \mqty{a \\ b} \\ \mqty{c & d} & e
  % \end{pmatrix}

  % pmatrix can be replaced with \mqty() - m quanitity - NOTE THE PARENs

  % the pmatrix in oneline:
  % \mqty(\mqty{\imat{2}} & \mqty{a \\ b} \\ \mqty{c & d} & e)

  % replace the () with others to get different bracketed matrix, or use:
  % \pmqty{}, \bmqty{}, etc.

  % you can use smqty{} and variations (always starting with s) for small matricies

  % \xmat{x}{n}{m}

  % \dmat{a,b,c} to put thing diagonally
    """
   
    if "%!tex nopreamble" in cell.lower() or "% !tex nopreamble" in cell.lower():
        preamble = ""

    with open(filename + ".tex", "w") as f:
        pitonReplace = r"""\begin{document}
\NewPitonEnvironment{Python}{m}
  {%
    \PitonOptions
      {
        tcolorbox,
        splittable=3,
        width=min,
        line-numbers,
        line-numbers =
         {
           format = \footnotesize\color{white}\sffamily ,
           sep = 2.5mm
         }
      }%
    \tcbset
      {
        enhanced,
        title=#1,
        fonttitle=\sffamily,
        left = 6mm,
        top = 0mm,
        bottom = 0mm,
        overlay=
         {%
            \begin{tcbclipinterior}%
                \fill[gray!80]
                    (frame.south west) rectangle
                    ([xshift=6mm]frame.north west);
            \end{tcbclipinterior}%
         }
      }
  }
  { }
        """;
        f.write(
            preamble + "\n" + cell#.replace(r"\begin{document}", pitonReplace)
        )

    # now go back to the home directory and run `latex` as defined in the variable below
    latex = "latexmk -pdf -pdflua -shell-escape -interaction=batchmode" if ("%!tex lualatex" in cell) else "latexmk -pdf -shell-escape -interaction=batchmode"
    first_time = "-lualatex='lualatex -draftmode %O %S'" if ("%!tex lualatex" in cell) else "-pdflatex='pdflatex -draftmode %O %S'"
    latex2 = latex.replace("pdf", "dvi")
    latex = "" # cus i dont want pdf anymore.
    # latex = "dvilualatex --shell-escape --interaction=batchmode" if ("%!tex lualatex" in cell) else "pdflatex -output-format=dvi -shell-escape -interaction=batchmode"
    # latex2 = ""
    get_ipy().run_cell(
        "!{latex2} {document}.tex > /dev/null 2>&1".format(document = filename, latex2 = latex2)
    );
   
    try:
        load(f'{filename}.sagetex.sage', verbose=False)
    except:
        display(html(f'<h2>no sage file found (finding {filename}.sagetex.sage)</h2>'))

    # asyncio.get_event_loop().run_until_complete(coro)
   
    # sage and pythontex.py have been ran at the same time. now proceed with 2nd latex compilation
    get_ipy().run_cell(
        dedent("""
        %%script bash
        {latex} {document}.tex > /dev/null 2>&1
        {latex2} {document}.tex > /dev/null 2>&1

        # dvipng -D 3000 -T tight {document}.dvi > /dev/null 2>&1
        dvisvgm --page=1- --output="%f%p-%P" --font-format=woff --exact-bbox {document}.dvi > /dev/null 2>&1
    """.format(document = filename, latex = latex, latex2 = latex2))
    )

    # import time
    # display(html.iframe(f"cell://{filename}.pdf?{time.time()}"))

    all_files = os.listdir('.')
    try:
        example_file = [f for f in all_files if f.startswith(f"{filename}1-")][0]
        total_pages = int(example_file.split('-')[1].split('.')[0])

        images = ""
        for i in range(1, total_pages + 1):
            current_img = f"{filename}{i}-{total_pages}"
            images += f"<img src='cell://{current_img}.svg?{time.time()}' style='min-width:500px; margin-top:5em; display:block'>"

            # old PNG version:
            # display( html(f"<img src='cell://{filename}1.png' style='min-width:500px; max-width:65%;'>") )
        display( html(f"<div style='height:27.5em; width:80%; overflow:overlay;'> {images} </div>") )
    except BaseException:
        display( html(f"<h2>no SVG output for {filename}.tex</h2>") )
