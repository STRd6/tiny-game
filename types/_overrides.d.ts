interface VibrationActuator {
  playEffect(effect: string, ...args: any[]): unknown
}

interface Gamepad {
  vibrationActuator: VibrationActuator
}
