# From a hack to a developer tool 

### The story of repo-grep

Back at university, I worked on a numerical model that had grown over decades — [Fortran]( https://en.wikipedia.org/wiki/Fortran) files, parameter tables, utilities, and conventions accumulated over many hands. To understand it, I had to answer simple but essential questions: where a variable was set, how a flux reached the surface layer, which routine applied a boundary condition. That meant a lot of grep in the terminal. It worked, but switching between editor and shell constantly broke the flow.

I was using [Emacs](https://www.gnu.org/software/emacs) , as many in my group did. One day I discovered that I could run [grep inside Emacs](https://www.gnu.org/software/emacs/manual/html_node/emacs/Grep-Searching.html). Results appeared in a dedicated buffer, and I could jump straight to the matching lines. It was a huge step up — but still repetitive. I had to type the search term and directory path every time. That got me wondering whether the editor could behave more like how I wanted to work.

A weekend with Google and StackOverflow answered that question. I learned that Emacs wasn’t just an editor. It was programmable. I figured out how to grab the word under the cursor and pass it into a search command. That first hack became a small tool: one keystroke to search for a symbol across the whole project. It kept me in the flow and quickly became part of my everyday toolkit.

The first version was completely tied to the model I was working on. I hard-coded the directory layout and all assumptions about the project structure. It worked perfectly — until I changed jobs. Overnight, the tool broke. The paths were different, the layout unfamiliar, and all my assumptions were gone. I still needed the functionality, but the tool had become useless outside its original environment.

So I generalised it. First with svn info, later with git rev-parse, I taught it to detect the project root automatically. I stripped out assumptions, made the logic repository-agnostic, and turned the hack into something portable. I used it like that for years — quietly, reliably, buried in my Emacs configuration.

Eventually I pulled it out and gave it its own repository. Around the same time, AI-assisted programming became available. Out of curiosity, I asked an AI tool to review the code. It liked the user experience — but it also flagged something I had never considered: the shell command construction wasn’t safe. There was a potential for [shell injection]( https://en.wikipedia.org/wiki/Code_injection#Shell_injection), the kind of thing you don’t worry about when you’re the only user of a private script. But now that the tool was public, I had a responsibility to fix it.

So I learned about input sanitisation, rewrote the command construction, added guardrails, and made the tool robust in a way it had never needed to be before. While I was at it, I documented it with a [tutorial]( https://github.com/BHFock/repo-grep/blob/main/docs/repo-grep-tutorial.md), cleaned up the functionality, and removed old assumptions. Over time, repo‑grep became something I felt comfortable publishing on [MELPA](https://melpa.org/#/repo-grep), making it easier for others to install and use.

The tool kept evolving. I added [ripgrep]( https://github.com/BurntSushi/ripgrep) support for speed on large repositories. I added multi-repository search for scientific workflows spread across several codebases. And I kept the power features that had grown naturally over the years — things like searching only for assignments to a variable, or only for calls to a subroutine — small conveniences that make it easier to trace data flow and control flow in large scientific models.

But some things never changed. The core idea remains exactly what it was on that first weekend: press one key, grep for the symbol under the cursor, and stay in the flow. For more than fifteen years now, some form of this tool has supported my work. Looking back, I’m glad I started that little hack at university. It grew with me, adapted to new environments, and quietly increased the amount of code I can work with. What began as a personal convenience became a small, reliable companion in scientific computing.

Hopefully [repo-grep.el](https://github.com/BHFock/repo-grep) is useful for others too.
