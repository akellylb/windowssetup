// Cloudflare Worker to serve R2 files with password protection
// Deploy this to protect your custom software downloads

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Configuration
    const PASSWORD = "your-secure-password-here"; // Change this!
    const R2_BUCKET_NAME = "software"; // Your R2 bucket name

    // Check for password in query string or header
    const authPassword = url.searchParams.get('key') || request.headers.get('X-Auth-Key');

    if (authPassword !== PASSWORD) {
      return new Response('Unauthorized - Invalid or missing password', {
        status: 401,
        headers: {
          'WWW-Authenticate': 'Basic realm="Secure Downloads"'
        }
      });
    }

    // Get filename from path
    const path = url.pathname.substring(1); // Remove leading slash

    if (!path) {
      return new Response('File path required', { status: 400 });
    }

    try {
      // Fetch from R2 (bind your R2 bucket in Worker settings)
      const object = await env.R2_BUCKET.get(path);

      if (!object) {
        return new Response('File not found', { status: 404 });
      }

      // Return the file
      return new Response(object.body, {
        headers: {
          'Content-Type': object.httpMetadata.contentType || 'application/octet-stream',
          'Content-Length': object.size,
          'Cache-Control': 'private, max-age=3600'
        }
      });
    } catch (error) {
      return new Response(`Error: ${error.message}`, { status: 500 });
    }
  }
};

/*
SETUP INSTRUCTIONS:

1. Create Worker:
   - Cloudflare Dashboard → Workers & Pages → Create Worker
   - Paste this code
   - Change PASSWORD on line 8

2. Bind R2 Bucket:
   - Worker Settings → Variables → R2 Bucket Bindings
   - Variable name: R2_BUCKET
   - R2 bucket: [your bucket name]

3. Deploy Worker:
   - Your worker URL: https://downloads.your-worker.workers.dev

4. Use in setup.ps1:
   - Update URLs to: https://downloads.your-worker.workers.dev/installer.exe?key=your-secure-password-here

5. Keep bucket PRIVATE (no public access needed)
*/
