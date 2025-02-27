import { InitiateLaunchUsecase } from "./initiateLaunchUsecase"

describe('Initiate Launch Usecase', () => {

    const usecase = new InitiateLaunchUsecase()

    it('Should initiate new launch', () => {
        // Given
        // When
        usecase.execute('rocket-id')

        // Then
    })
})