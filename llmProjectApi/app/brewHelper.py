import os
import re
import shlex
import subprocess
from pathlib import Path
from runCommand import run

class BrewHelper:
    FormulaRepoUrl = 'https://github.com/Homebrew/homebrew-core'
    CaskRepoUrl = 'https://github.com/Homebrew/homebrew-cask'
    
    rootDir = os.path.dirname(os.path.abspath(__file__)) + '/repo'
    formulaDir = rootDir + '/' + FormulaRepoUrl.split('/')[-1]
    caskDir = rootDir + '/' + CaskRepoUrl.split('/')[-1]
    
    def __init__(self):
        # self.data = []
        pass

    def cloneRepo(self, rootDir: str, url: str, date: str = "5 weeks"):
        """
        Formula repo: `https://github.com/Homebrew/homebrew-core`
        Cask repo: `https://github.com/Homebrew/homebrew-cask`
        """
        
        # Ensure the folder exists
        Path(rootDir).mkdir(exist_ok=True)
        
        command = f'git -C {rootDir} clone --shallow-since="{date}" --single-branch {url}'
        args = shlex.split(command)
        try:
            result = subprocess.run(args, capture_output=True, text=True)
            # print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"An error occurred: {e} \n {e.stderr}")
        
        # Repair git dir history
        repoDir = rootDir + '/' + url.split('/')[-1]
        run("git repack -d", repoDir)
        run(f'git fetch --shallow-since={date}', repoDir)
            
    def updateCoreRepo(self, rootDir: str):
        repoDirName = 'homebrew-core'
        repoDirPath = rootDir + '/' + repoDirName
        # Clone if repo does not exist
        if not (os.path.exists(repoDirPath) and os.path.isdir(repoDirPath)):
            self.cloneRepo(rootDir, self.FormulaRepoUrl)
            
        # FUTURE maybe implement checking if requested date is within the known history
        # Fetch to depth
        #, date: str = "1 week"
        # run(f'git fetch --shallow-since={date}', repoDirPath)
        
        # Pull new changes
        run("git pull -f", repoDirPath)

    def getNewFormula(self, date:str, pathToRepo: str = formulaDir) -> list[str]:
        command = [
            'git', '-C', pathToRepo, 'log', '--name-only', f'--since={date}', '--diff-filter=A',
            '--pretty=format:', '--', 'Formula'
        ]

        try:
            result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
            
            # Filter out empty lines
            output = result.stdout.strip().splitlines()
            filtered_output = [line for line in output if line]  # This removes empty lines
            return filtered_output
        
            # Print the filtered output
            for line in filtered_output:
                print(line)

        except subprocess.CalledProcessError as e:
            print(f"An error occurred when : {e.stderr}")
            raise
        
        
        
class RubyParser:
    def parseRubyForKey(self, filePath: str, searchKey: str):
        # Compile a regex pattern to match the desired line format
        pattern = re.compile(r'^\s*' + re.escape(searchKey) + r'\s*(.*)$')
        
        with open(filePath, 'r') as file:
            for line in file:
                match = pattern.match(line)
                if match:
                    return match.group(1).strip()[1:-1]
        return ""
    
    def __init__(self, rubyFilePath: str):
        # self.data = []
        self.name = rubyFilePath.split('/')[-1][:-3]
        self.description = self.parseRubyForKey(rubyFilePath, 'desc')
        self.homepage = self.parseRubyForKey(rubyFilePath, 'homepage')
        self.license = self.parseRubyForKey(rubyFilePath, 'license')
        self.gitRepository = self.parseRubyForKey(rubyFilePath, 'head')
        pass
    
    def __str__(self):
        return f"""{self.name}: {self.description}\n- License: {self.license} Link(s): {self.homepage} {self.gitRepository}"""
        
        

if __name__ == '__main__':
    # getNewFormula("/Users/mcbabac/Downloads/homebrew-core/")

    
    brew = BrewHelper()
    brew.updateCoreRepo(brew.rootDir)
    
    for formula in brew.getNewFormula(brew.formulaDir, "5 days"):
        formulaFullPath = brew.formulaDir + '/' + formula
        print(RubyParser(formulaFullPath))

    pass
    




