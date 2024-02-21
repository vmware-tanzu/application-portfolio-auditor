/*
 * Script to download and transform all required external staic assets used by the "Application Portfolio Auditor" user interface.
 */

import axios from 'axios'
import fs from 'fs'
import path from 'path'
import sharp from 'sharp' // to crop the images
import unzipper from 'unzipper' // to unpack the zip files and extract images
import cheerio from 'cheerio' // to parse HTML

import { fileURLToPath } from 'url'

// Determine the root directory of the project
const baseDirectory = '/out'

const requestTimeout = 10000

const requestHeaders = {
  'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_1_2 AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
}

const redColor = '\x1b[31m'
const greenColor = '\x1b[32m'
const noColor = '\x1b[0m'

// Get the directory name of the current module
const __dirname = path.dirname(fileURLToPath(import.meta.url))

// Path to list of all assets
const assetListPath = path.join(__dirname, 'assets.json')

// Function to create a directory if it doesn't exist
function ensureDirectoryExists(directory) {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true })
  }
}

// Function to check if an asset already exists
function assetExists(assetPath) {
  return fs.existsSync(assetPath)
}

// Function to crop an image
async function cropImage(inputPath, cropOptions) {
  try {
    // Temp out file
    const tempOutputPath = inputPath + '.cropped'

    // Read the input image file
    const image = sharp(inputPath)

    // Apply crop operation
    await image
      .extract({
        left: cropOptions.left,
        top: cropOptions.top,
        width: cropOptions.width,
        height: cropOptions.height
      })
      .toFile(tempOutputPath)

    // Replace the input file with the cropped temporary file
    fs.copyFileSync(tempOutputPath, inputPath)
    fs.unlinkSync(tempOutputPath)

    console.log('       Image file cropped successfully.')
  } catch (error) {
    console.error(`${redColor}[ERROR] Failed to crop image '${inputPath}' :${noColor}`, error.message)
  }
}

// Function to unzip a file and extract its content
async function unzipAsset(zipFilePath, unzipOptions) {
  // Return a promise that resolves when the unzip process is complete
  return new Promise((resolve, reject) => {
    try {
      // Create temporary folder
      const tempOutputPath = zipFilePath + 'tmp'
      ensureDirectoryExists(tempOutputPath)

      // Create a read stream from the zip file
      const readStream = fs.createReadStream(zipFilePath)
      // Pipe the read stream into the unzipper
      readStream
        .pipe(unzipper.Extract({ path: tempOutputPath }))
        .on('close', () => {
          resolve()
          console.log('       File unzipped successfully.')
          for (let entry of unzipOptions) {
            let targetFile = path.join(tempOutputPath, entry.file)
            if (fs.existsSync(targetFile)) {
              fs.unlinkSync(zipFilePath)
              fs.copyFileSync(path.join(tempOutputPath, entry.file), zipFilePath)
            } else {
              console.log(`${redColor}[ERROR] File does not exist: '${targetFile}'`)
            }
          }
          // Delete temporary folder
          if (tempOutputPath) {
            fs.rmSync(tempOutputPath, { recursive: true, force: true })
          }
        })
        .on('error', reject)
    } catch (error) {
      console.error(`${redColor}[ERROR] Failed to unzip image '${zipFilePath}' :${noColor}`, error)
    }
  })
}

// Function to download an asset
async function downloadAsset(url, targetName, targetDir, description, crop, unzip, extractFirstSVG) {
  let writer
  try {
    const targetDirectory = path.join(baseDirectory, 'public', targetDir)
    ensureDirectoryExists(targetDirectory)
    const assetPath = path.join(targetDirectory, targetName)

    // Check if asset already exists, if yes, return
    if (assetExists(assetPath)) {
      console.log(`[INFO] ${description} (${greenColor}'${targetName}'${noColor}) is already available`)
      return
    } else {
      console.log(`[INFO] Downloading ${description} (${targetName})`)
    }

    const response = await axios({
      url: url,
      method: 'GET',
      responseType: extractFirstSVG ? 'text' : 'stream',
      headers: requestHeaders,
      timeout: requestTimeout
    })

    if (extractFirstSVG) {
      // Extract and save the first SVG element
      const content = cheerio.load(response.data)
      const svgElement = content('svg').first().prop('outerHTML')
      if (svgElement) {
        fs.writeFileSync(assetPath, svgElement)
        console.log(`       Downloaded ${greenColor}'${targetName}'${noColor}`)
      } else {
        console.error(`${redColor}[ERROR] No SVG element found in the HTML page: '${url}'${noColor}`)
      }
    } else {
      writer = fs.createWriteStream(assetPath)
      response.data.pipe(writer)
      return new Promise((resolve, reject) => {
        writer.on('finish', () => {
          console.log(`       Downloaded ${greenColor}'${targetName}'${noColor}`)
          if (crop) {
            cropImage(assetPath, crop)
              .then(() => resolve())
              .catch(reject)
          } else if (unzip) {
            unzipAsset(assetPath, unzip)
              .then(() => resolve())
              .catch(reject)
          } else {
            resolve()
          }
        })
        writer.on('error', reject)
      })
    }
  } catch (error) {
    console.error(`${redColor}[ERROR] Failed to download '${url}' :${noColor}`, error.message)

    if (error.response && error.response.data) {
      // Close response stream before timeout and output response
      let streamString = ''
      error.response.data.setEncoding('utf8')
      error.response.data
        .on('data', (utf8Chunk) => {
          streamString += utf8Chunk
        })
        .on('end', () => {
          console.error(streamString)
        })
    }

    // Close the stream if it's still open
    if (writer) {
      writer.end()
    }
  }
}

// Main function to download all assets
async function downloadAssets() {
  try {
    const assetList = JSON.parse(fs.readFileSync(assetListPath))
    for (const asset of assetList) {
      await downloadAsset(asset.url, asset.targetName, asset.targetDir, asset.description, asset.crop, asset.unzip, asset.extractFirstSVG)
    }
  } catch (error) {
    console.error(`${redColor}[ERROR] Failer to download assets:${noColor} ${error.message}`)
  }
}

// Start downloading assets
downloadAssets()
