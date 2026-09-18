import { useEffect, useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { onNuiEvent } from './utils/onNui';
import { sendNuiEvent } from './utils/sendNui';

import './index.css'

function App() {
  const [showBanner, setShowBanner] = useState(false)
  const [uiConfig, setConfig] = useState({
    thumbnail: 'C-Scripts',
    color: '#7af9a6'
  })
  const [player, setPlayer] = useState({
    name: 'PlayerOne',
    profile: 'https://i.imgur.com/8Km9tLL.png',
    background: 'https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif',
    sound: 'https://www.myinstants.com/media/sounds/anime-wow-sound-effect.mp3',
    color: '#ffcc00',
    message: 'Welcome to the server!',
    duration: 5000,
    volumn: 0.4
  })

  const muteMusicRef = useRef(false)
  const audioRef = useRef<HTMLAudioElement | null>(null)

  useEffect(() => {
    sendNuiEvent('UILoaded', { loaded: true });
    onNuiEvent('setConfig', (data) => {
      setConfig(data.cfg)
    })
  }, []);

  useEffect(() => {
    onNuiEvent('showBanner', (data) => {
      const updatedPlayer = { ...player, ...data }
      setPlayer(updatedPlayer)
      setShowBanner(true)

      if (!muteMusicRef.current && updatedPlayer.sound) {
        const audio = new Audio(updatedPlayer.sound)
        audio.volume = player.volumn
        audio.play()
        audioRef.current = audio
      }

      const hideDelay = updatedPlayer.duration || 5000
      const timer = setTimeout(() => {
        setShowBanner(false)
        if (audioRef.current) {
          audioRef.current.pause()
          audioRef.current.currentTime = 0
          audioRef.current = null
        }
      }, hideDelay)

      return () => clearTimeout(timer)
    })
    
    onNuiEvent('MuteMusic', (data) => {
      muteMusicRef.current = data?.mute ?? true
    })
  }, [])

  return (
    <div className="app-container">
      <AnimatePresence>
        {showBanner && (
          <motion.div
            initial={{ x: 300, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: 300, opacity: 0 }}
            transition={{ type: 'tween', duration: 0.5 }}
            className="welcome-banner"
            style={{
              backgroundImage: `url(${player.background})`,
              backgroundSize: 'cover',
              backgroundPosition: 'center',
            }}
          >
            <div className="banner-overlay">
              <img src={player.profile} alt="profile" style={{borderColor: uiConfig.color}} className="banner-profile" />
              <div className="banner-text">
                <h2 style={{ color: player.color }}>{player.name}</h2>
                <p>{player.message}</p>
              </div>
              <div className="thumbnail">
                <span style={{color: uiConfig.color}}>{uiConfig.thumbnail}</span>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default App
