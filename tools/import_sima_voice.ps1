$ErrorActionPreference = 'Stop'

$ffmpeg = 'D:\ffmpeg-8.0.1-essentials_build\ffmpeg-8.0.1-essentials_build\bin\ffmpeg.exe'
$whisper = 'C:\Users\jia\AppData\Local\Python\pythoncore-3.14-64\Scripts\whisper.exe'
$outputRoot = Join-Path $PSScriptRoot '..\audio\voice_source'

$videos = @(
  @{ bvid = 'BV1N43t6UEG5'; character = '司马遹' },
  @{ bvid = 'BV1zw386CEMv'; character = '司马衷' },
  @{ bvid = 'BV1ix3b6MEHR'; character = '司马亮' },
  @{ bvid = 'BV1TC3b6dEu3'; character = '司马玮' },
  @{ bvid = 'BV1gB3b6FEgC'; character = '司马伦' },
  @{ bvid = 'BV14w3b69EWX'; character = '司马冏' },
  @{ bvid = 'BV18Z3t64Ena'; character = '司马颙' },
  @{ bvid = 'BV1bf3t6dENY'; character = '司马颖' },
  @{ bvid = 'BV1zJ3b6GEcJ'; character = '司马乂' },
  @{ bvid = 'BV1sM3b6SE7y'; character = '司马越' }
)

function Get-Seconds([string]$timestamp) {
  $parts = $timestamp.Trim().Split(':')
  if ($parts.Count -eq 2) {
    return [double]$parts[0] * 60 + [double]($parts[1] -replace ',', '.')
  }
  return [double]$parts[0] * 3600 + [double]$parts[1] * 60 + [double]($parts[2] -replace ',', '.')
}
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

foreach ($video in $videos) {
  $characterDir = Join-Path $outputRoot $video.character
  $segmentsDir = Join-Path $characterDir 'segments'
  New-Item -ItemType Directory -Force -Path $segmentsDir | Out-Null

  $metadata = Invoke-RestMethod -Uri ("https://api.bilibili.com/x/web-interface/view?bvid=" + $video.bvid) -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
  if ($metadata.code -ne 0) { throw "Cannot load $($video.bvid): $($metadata.message)" }

  $aid = $metadata.data.aid
  $cid = $metadata.data.cid
  $play = Invoke-RestMethod -Uri ("https://api.bilibili.com/x/player/playurl?avid=$aid&cid=$cid&fnval=16&fnver=0&fourk=1") -Headers @{ 'User-Agent' = 'Mozilla/5.0'; 'Referer' = 'https://www.bilibili.com/' }
  $audioStream = $play.data.dash.audio | Sort-Object bandwidth -Descending | Select-Object -First 1
  if ($null -eq $audioStream) { throw "No audio stream for $($video.bvid)" }

  $sourceM4s = Join-Path $characterDir 'source.m4s'
  $sourceMp3 = Join-Path $characterDir 'source.mp3'
  Invoke-WebRequest -Uri $audioStream.baseUrl -OutFile $sourceM4s -Headers @{ 'User-Agent' = 'Mozilla/5.0'; 'Referer' = 'https://www.bilibili.com/' }
  & $ffmpeg -y -hide_banner -loglevel error -i $sourceM4s -vn -c:a libmp3lame -q:a 2 $sourceMp3
  if ($LASTEXITCODE -ne 0) { throw "ffmpeg conversion failed for $($video.character)" }

  & $whisper $sourceMp3 --model base --language Chinese --task transcribe --output_format vtt --output_dir $characterDir --fp16 False
  if ($LASTEXITCODE -ne 0) { throw "Whisper transcription failed for $($video.character)" }

  $vtt = Get-Content -LiteralPath (Join-Path $characterDir 'source.vtt')
  $records = [System.Collections.Generic.List[object]]::new()
  for ($i = 0; $i -lt $vtt.Count; $i++) {
    if ($vtt[$i] -match '^((?:\d{2}:)?\d{2}:\d{2}[\.,]\d{3})\s+-->\s+((?:\d{2}:)?\d{2}:\d{2}[\.,]\d{3})') {
      $textLines = [System.Collections.Generic.List[string]]::new()
      $i++
      while ($i -lt $vtt.Count -and -not [string]::IsNullOrWhiteSpace($vtt[$i])) {
        $textLines.Add($vtt[$i].Trim())
        $i++
      }
      $text = ($textLines -join ' ') -replace '<[^>]+>', ''
      if ($text) {
        $records.Add([pscustomobject]@{ Start = Get-Seconds $matches[1]; End = Get-Seconds $matches[2]; Text = $text })
      }
    }
  }

  $transcript = [System.Collections.Generic.List[string]]::new()
  $transcript.Add("角色：$($video.character)")
  $transcript.Add("来源：https://www.bilibili.com/video/$($video.bvid)")
  $transcript.Add("视频标题：$($metadata.data.title)")
  $transcript.Add('')
  $index = 1
  foreach ($record in $records) {
    $duration = [Math]::Max(0.15, $record.End - $record.Start)
    $clip = Join-Path $segmentsDir (('{0:D2}.mp3' -f $index))
    & $ffmpeg -y -hide_banner -loglevel error -ss $record.Start.ToString('0.000', [cultureinfo]::InvariantCulture) -t $duration.ToString('0.000', [cultureinfo]::InvariantCulture) -i $sourceMp3 -c:a libmp3lame -q:a 2 $clip
    if ($LASTEXITCODE -ne 0) { throw "Segment export failed for $($video.character), item $index" }
    $transcript.Add(('{0:D2}.mp3 [{1:0.000}-{2:0.000}] {3}' -f $index, $record.Start, $record.End, $record.Text))
    $index++
  }
  [System.IO.File]::WriteAllLines((Join-Path $characterDir '台词.txt'), $transcript, [System.Text.UTF8Encoding]::new($false))
}
