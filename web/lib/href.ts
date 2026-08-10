export const BASE_PATH = process.env.NEXT_PUBLIC_BASE_PATH || "";

/**
 * Prefix an internal path with the deploy base path (GitHub Pages subpath).
 * Static export uses trailingSlash, so non-file paths get a trailing slash so
 * GitHub Pages resolves them to `<path>/index.html`. File paths (.patch, .md)
 * keep their exact name.
 */
export const href = (p: string) => {
  if (!p.startsWith("/") || p.startsWith("//")) return p;
  const prefixed = BASE_PATH + p;
  if (/\.[a-z0-9]+$/i.test(p) || p.includes("#") || p.includes("?")) return prefixed;
  return prefixed + "/";
};
