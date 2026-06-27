import os
import unittest

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost/test")
os.environ.setdefault("GEMINI_API_KEY", "test-key")

from app.routes.tts import _extract_audio_base64


class TtsAudioExtractionTest(unittest.TestCase):
    def test_extracts_audio_from_interactions_steps_content(self) -> None:
        payload = {
            "id": "v1_test",
            "status": "completed",
            "steps": [
                {
                    "content": [
                        {
                            "mime_type": "audio/l16",
                            "data": "BASE64_AUDIO_FROM_STEPS",
                        }
                    ]
                }
            ],
        }

        self.assertEqual(
            _extract_audio_base64(payload),
            "BASE64_AUDIO_FROM_STEPS",
        )

    def test_extracts_audio_from_camel_case_mime_type(self) -> None:
        payload = {
            "steps": [
                {
                    "content": [
                        {
                            "mimeType": "audio/pcm;rate=24000",
                            "data": "BASE64_AUDIO_CAMEL_CASE",
                        }
                    ]
                }
            ],
        }

        self.assertEqual(
            _extract_audio_base64(payload),
            "BASE64_AUDIO_CAMEL_CASE",
        )


if __name__ == "__main__":
    unittest.main()
