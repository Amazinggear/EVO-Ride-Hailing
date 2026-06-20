const sharp = require('sharp');
const fs = require('fs');

async function processLogo() {
  try {
    const inputPath = 'public/logo.png';
    const outputPath = 'public/logo_processed.png';
    
    // Get the image buffer
    const buffer = fs.readFileSync(inputPath);
    
    // Process image: make anything that is close to black transparent, then trim empty space
    await sharp(buffer)
      // Extract alpha channel based on lightness (black becomes transparent)
      // Actually, we can use a trick: composite it over transparent if we know how to key color
      // Or just use the fact that green channel has the logo.
      .ensureAlpha()
      // Let's use raw buffer manipulation to make black pixels transparent
      .raw()
      .toBuffer({ resolveWithObject: true })
      .then(async ({ data, info }) => {
        // Create a new buffer
        const outData = Buffer.alloc(data.length);
        for (let i = 0; i < data.length; i += info.channels) {
          const r = data[i];
          const g = data[i + 1];
          const b = data[i + 2];
          const a = data[i + 3];
          
          // If dark (sum of RGB < 60), make it transparent
          if (r + g + b < 60) {
            outData[i] = 0;
            outData[i + 1] = 0;
            outData[i + 2] = 0;
            outData[i + 3] = 0;
          } else {
            outData[i] = r;
            outData[i + 1] = g;
            outData[i + 2] = b;
            outData[i + 3] = 255;
          }
        }
        
        await sharp(outData, { raw: { width: info.width, height: info.height, channels: 4 } })
          .trim() // Crop all the new transparent padding!
          .png()
          .toFile(outputPath);
      });
      
    // Overwrite original
    fs.copyFileSync(outputPath, inputPath);
    console.log('Done processing logo!');
  } catch (err) {
    console.error('Error processing logo:', err);
  }
}

processLogo();
