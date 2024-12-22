/**
@Author       - Infosys
@Name         - CSX_CMP_GenerateDeclineLetterScheduler Schedulable ControllerApex class
@Created Date - 5/31/2024
@Description  - This Schedulable Apex class is used to schedule the CSX_CMP_GenerateDeclineLetterBatch Emails
@RICEFW reference - CMP-E-0458
*/
public with sharing class CSX_CMP_GenerateDeclineLetterScheduler implements Schedulable {
	public void execute(SchedulableContext sc) {
		CSX_CMP_GenerateDeclineLetterBatch declineLetterGenerationBatch = new CSX_CMP_GenerateDeclineLetterBatch();
		Database.executeBatch(declineLetterGenerationBatch, 20);
	}
}