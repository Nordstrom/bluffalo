/*
 * main.swift
 * Copyright (c) 2017 Nordstrom, Inc. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

// MARK: - Parse CLI arguments

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
    outFile: outputFileOption.value!,
    module: moduleOption.value,
    imports: importsOption.value
)

// MARK: - Generate fakes

do {
    try generateFake(file: args.file, outFile: args.outFile, module: args.module, imports: args.imports)
}
catch {
    exit(EXIT_FAILURE)
}

exit(EXIT_SUCCESS)
