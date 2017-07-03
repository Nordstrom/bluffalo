import Foundation

// MARK - Parse CLI arguments

let cli = CommandLineParser()

let fileOption = StringOption(shortFlag: "f", longFlag: "file", required: true, helpMessage: "The input file")
let outputFileOption = StringOption(shortFlag: "o", longFlag: "outFile", required: true, helpMessage: "The output file")
let moduleOption = StringOption(shortFlag: "m", longFlag: "module", required: false, helpMessage: "The module that your real class lives in")
let importsOption = StringOption(shortFlag: "i", longFlag: "imports", required: false, helpMessage: "Any extra imports you want added to the file")

cli.addOptions(fileOption, outputFileOption, moduleOption, importsOption)

do {
    try cli.parse()
}
catch {
    cli.printUsage()
    exit(EX_USAGE)
}

let args = Arguments(
    file: fileOption.value!,
    outputFile: outputFileOption.value!,
    module: moduleOption.value,
    imports: importsOption.value
)

// MARK - Generate fakes

do {
    let fileGenerator = FileGenerator()
    try fileGenerator.generate(file: args.file, outFile: args.outputFile, module: args.module, imports: args.importList())
}
catch {
    exit(EXIT_FAILURE)
}

exit(EXIT_SUCCESS)
