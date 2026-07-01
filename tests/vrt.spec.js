import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { expect, test } from '@playwright/test';

const examples = ['01-hello', '02-css', '03-elm-ui', '04-elm-css', '05-tailwind'];

for (const example of examples) {
  const previewsPath = join(process.cwd(), `examples/${example}/dist/shiori-previews.json`);
  if (!existsSync(previewsPath)) {
    continue;
  }
  const previews = JSON.parse(readFileSync(previewsPath, 'utf-8'));

  test.describe(`Shiori VRT - ${example}`, () => {
    test.beforeEach(async ({}, testInfo) => {
      test.skip(testInfo.project.name !== example, 'Skip other examples');
    });

    for (const path of previews) {
      test(`Snapshot for ${path}`, async ({ page }) => {
        page.on('console', msg => console.log(`[BROWSER CONSOLE ${example}]`, msg.text()));
        page.on('pageerror', err => console.error(`[BROWSER ERROR ${example}]`, err.message));
        await page.goto(path);
        await page.waitForLoadState('networkidle');
        // Elmの初期化と初期レンダリング完了を待つ
        await page.waitForSelector('body > div');
        await expect(page).toHaveScreenshot(`${example}_${path.replace(/\//g, '_')}.png`, {
          fullPage: true
        });
      });
    }
  });
}
