import { Entity, EntityConstructor } from "./core";

export interface AdHocEntity extends Entity { }

export interface AdHocEntityConstructor extends EntityConstructor<AdHocEntity> { }
