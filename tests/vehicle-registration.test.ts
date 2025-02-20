import { describe, it, expect, beforeEach } from "vitest"

describe("Vehicle Registration Contract", () => {
  let mockStorage: Map<string, any>
  let vehicleNonce: number
  
  beforeEach(() => {
    mockStorage = new Map()
    vehicleNonce = 0
  })
  
  const mockContractCall = (method: string, args: any[], sender: string) => {
    switch (method) {
      case "register-vehicle":
        const [model, licensePlate] = args
        if (Array.from(mockStorage.values()).some((v: any) => v.licensePlate === licensePlate)) {
          return { success: false, error: "Vehicle already registered" }
        }
        vehicleNonce++
        mockStorage.set(`vehicle-${vehicleNonce}`, {
          owner: sender,
          model,
          licensePlate,
          status: 1, // STATUS_ACTIVE
          registrationDate: 100, // Mock block height
        })
        return { success: true, value: vehicleNonce }
      case "update-vehicle-status":
        const [vehicleId, newStatus] = args
        const vehicle = mockStorage.get(`vehicle-${vehicleId}`)
        if (!vehicle || (vehicle.owner !== sender && sender !== "CONTRACT_OWNER")) {
          return { success: false, error: "Not authorized" }
        }
        vehicle.status = newStatus
        mockStorage.set(`vehicle-${vehicleId}`, vehicle)
        return { success: true }
      case "get-vehicle":
        return { success: true, value: mockStorage.get(`vehicle-${args[0]}`) }
      case "get-vehicle-by-license-plate":
        const foundVehicle = Array.from(mockStorage.values()).find((v: any) => v.licensePlate === args[0])
        return { success: true, value: foundVehicle ? [foundVehicle] : [] }
      case "get-vehicles-by-owner":
        const ownerVehicles = Array.from(mockStorage.values()).filter((v: any) => v.owner === args[0])
        return { success: true, value: ownerVehicles }
      default:
        return { success: false, error: "Method not found" }
    }
  }
  
  it("should register a vehicle", () => {
    const result = mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    expect(result.success).toBe(true)
    expect(result.value).toBe(1)
  })
  
  it("should not register a vehicle with duplicate license plate", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    const result = mockContractCall("register-vehicle", ["Tesla Model S", "ABC123"], "owner2")
    expect(result.success).toBe(false)
  })
  
  it("should update vehicle status", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    const result = mockContractCall("update-vehicle-status", [1, 2], "owner1")
    expect(result.success).toBe(true)
  })
  
  it("should not allow unauthorized status update", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    const result = mockContractCall("update-vehicle-status", [1, 2], "owner2")
    expect(result.success).toBe(false)
  })
  
  it("should get vehicle details", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    const result = mockContractCall("get-vehicle", [1], "anyone")
    expect(result.success).toBe(true)
    expect(result.value.model).toBe("Tesla Model 3")
  })
  
  it("should get vehicle by license plate", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    const result = mockContractCall("get-vehicle-by-license-plate", ["ABC123"], "anyone")
    expect(result.success).toBe(true)
    expect(result.value.length).toBe(1)
    expect(result.value[0].model).toBe("Tesla Model 3")
  })
  
  it("should get vehicles by owner", () => {
    mockContractCall("register-vehicle", ["Tesla Model 3", "ABC123"], "owner1")
    mockContractCall("register-vehicle", ["Tesla Model S", "XYZ789"], "owner1")
    const result = mockContractCall("get-vehicles-by-owner", ["owner1"], "anyone")
    expect(result.success).toBe(true)
    expect(result.value.length).toBe(2)
  })
})

