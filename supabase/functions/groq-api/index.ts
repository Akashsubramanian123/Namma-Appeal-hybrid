import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { requestBody, targetApi } = await req.json()
    
    let url = 'https://api.groq.com/openai/v1/chat/completions'
    let authHeader = `Bearer ${Deno.env.get('GROQ_API_KEY')}`

    // Intercept if target is Gemini
    if (targetApi === 'gemini') {
      const geminiKeys = [
        Deno.env.get('GEMINI_KEY_1'),
        Deno.env.get('GEMINI_KEY_2'),
        Deno.env.get('GEMINI_KEY_3'),
        Deno.env.get('GEMINI_KEY_4')
      ].filter(Boolean);
      
      const randomKey = geminiKeys[Math.floor(Math.random() * geminiKeys.length)];
      // Route to standard Gemini Developer API endpoint
      url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${randomKey}`
      authHeader = '' 
    }

    const headers: Record<String, String> = { 'Content-Type': 'application/json' }
    if (authHeader) headers['Authorization'] = authHeader

    const response = await fetch(url, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(requestBody),
    })

    const data = await response.json()
    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})