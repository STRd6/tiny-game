interface VibrationActuator {
  playEffect(effect: string, ...args: any[])
}

interface Gamepad {
  vibrationActuator: VibrationActuator
}
